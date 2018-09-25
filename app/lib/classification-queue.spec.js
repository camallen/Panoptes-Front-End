import { expect } from 'chai';
import sinon from 'sinon';
import ClassificationQueue from './classification-queue';
import FakeLocalStorage from '../../test/fake-local-storage';
import { FakeApiClient, FakeResource } from '../../test/fake-api-client';

import apiClient from 'panoptes-client/lib/api-client';
function mockPanoptesResource(type, options) {
  const resource = apiClient.type(type).create(options);
  apiClient._typesCache = {};
  sinon.stub(resource, 'save').callsFake(() => Promise.resolve(resource));
  sinon.stub(resource, 'get');
  sinon.stub(resource, 'delete');
  return resource;
}

describe('ClassificationQueue', function() {
  it('sends classifications to the backend', function() {
    let apiClient = new FakeApiClient();
    let storage = new FakeLocalStorage();

    let classificationData = {annotations: [], metadata: {}};
    let classificationQueue = new ClassificationQueue(storage, apiClient);
    classificationQueue.add(classificationData);

    expect(apiClient.saves).to.have.lengthOf(1);
  });

  it('keeps classifications in localStorage if backend fails', function(done) {
    let apiClient = new FakeApiClient({canSave: () => { return false; }});
    let storage = new FakeLocalStorage();

    let classificationData = {annotations: [], metadata: {}};
    let classificationQueue = new ClassificationQueue(storage, apiClient);
    classificationQueue.add(classificationData)
    .then(function () {
      expect(apiClient.saves).to.have.lengthOf(0);
      expect(classificationQueue.length()).to.equal(1);
    })
    .then(done, done);
  });

  describe.only('with a slow network connection', function () {
    let apiClient;
    let classificationQueue;
    let saveSpy;
    let classification = mockPanoptesResource('classification', {
      id: 1,
      annotations: [
        {
          task: 'T0',
          value: 'something'
        },
        {
          task: 'T1',
          value: 1
        }
      ]
    });
    before(function () {
      saveSpy = sinon.stub(FakeResource.prototype, 'save').callsFake(function() {
        // stub save so that the API call never completes.
        // console.log('i am the handler of the classification save function! not ye!')
        return Promise.resolve(classification)
      });
      apiClient = new FakeApiClient();
      classificationQueue = new ClassificationQueue(window.localStorage, apiClient);
      classificationQueue.add({annotations: [], metadata: {}});
      classificationQueue.add({annotations: [], metadata: {}});
    });
    after(function () {
      saveSpy.restore();
    });
    it('saves each classification once', function () {
      expect(saveSpy.callCount).to.equal(2);
    });
  });
});
