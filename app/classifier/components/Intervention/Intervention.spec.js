import React from 'react';
import { mount } from 'enzyme';
import { expect } from 'chai';
import sinon from 'sinon';
import Intervention from './Intervention';
import { Markdown } from 'markdownz'

describe('Intervention', () => {
  let wrapper;
  const intervention = { message: 'Hello!' };
  const { message } = intervention;
  const user = {
    id: 'a',
    update: sinon.stub().callsFake(() => {
      return { save: () => true };
    })
  };
  before(() => {
    wrapper = mount(
      <Intervention
        intervention={intervention}
        user={user}
      />);
  });
  it('should render', () => {
    expect(wrapper).to.be.ok;
  });
  it('should show a notification message', () => {
    const newlineMsg = intervention.message + "\n"
    expect(wrapper.find(Markdown).text()).to.equal(newlineMsg);
  });
  describe('opt-out checkbox', () => {
    let optOut;
    before(() => {
      optOut = wrapper.find('input[type="checkbox"]');
      optOut.simulate('change');
    });
    after(() => {
      user.update.resetHistory();
    });
    it('should update the user when checked/unchecked', () => {
      expect(user.update.callCount).to.equal(1);
    });
    it('should set the user opt-out preference', () => {
      const changes = { intervention_notifications: true }
      expect(user.update.calledWith(changes)).to.be.true;
    })
  });
});
