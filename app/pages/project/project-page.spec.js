import React from 'react';
import { shallow, mount } from 'enzyme';
import { expect } from 'chai';
import { project, workflow } from '../dev-classifier/mock-data';
import ProjectPage from './project-page';
import { sugarClient } from 'panoptes-client/lib/sugar';
import sinon from 'sinon';

function Page() {
  return (
    <p>Hello world!</p>
  );
}

describe('ProjectPage', () => {
  const background = {
    src: 'the project background image url'
  };

  it('should render without crashing', () => {
    shallow(<ProjectPage><Page /></ProjectPage>);
  });

  it('should render the project nav bar', () => {
    const wrapper = shallow(<ProjectPage><Page /></ProjectPage>);
    const navElement = wrapper.find('ProjectNavbar');
    expect(navElement).to.have.lengthOf(1);
  });

  it('should render the project nav bar as its first child', () => {
    const wrapper = shallow(<ProjectPage><Page /></ProjectPage>);
    const navBar = wrapper.children().first().children().first();
    expect(navBar.name()).to.equal('ProjectNavbar');
  });

  it('should pass background, project and workflow props to its children', () => {
    const wrapper = shallow(<ProjectPage background={background} project={project} workflow={workflow}><Page /></ProjectPage>);
    const child = wrapper.find('Page');
    expect(child.props().background).to.equal(background);
    expect(child.props().project).to.equal(project);
    expect(child.props().workflow).to.equal(workflow);
  });

  describe('with a launch-approved project', () => {
    project.launch_approved = true;
    const wrapper = shallow(<ProjectPage project={project} ><Page /></ProjectPage>);
    const disclaimer = wrapper.find('Translate[className="project-disclaimer"]');
    it('should not render the Zooniverse disclaimer.', () => {
      expect(disclaimer).to.have.lengthOf(0);
    });
  });

  describe('without approval', () => {
    project.launch_approved = false;
    const wrapper = shallow(<ProjectPage project={project} ><Page /></ProjectPage>);
    const disclaimer = wrapper.find('Translate[className="project-disclaimer"]');
    it('should render the Zooniverse disclaimer.', () => {
      expect(disclaimer).to.have.lengthOf(1);
    });
    it('should render the disclaimer immediately after its children.', () => {
      expect(wrapper.childAt(1).name()).to.equal('Page');
      expect(wrapper.childAt(2)).to.deep.equal(disclaimer);
    });
  });

  describe('on the home page', () => {
    let wrapper;
    beforeEach(() => {
      project.slug = 'test/project';
      project.configuration = {};
      project.configuration.announcement = 'This is a test announcement';
      const mockLocation = {
        pathname: `/projects/${project.slug}`
      };
      const routes = [];
      routes[2] = {};
      wrapper = shallow(
        <ProjectPage
          location={mockLocation}
          routes={routes}
          project={project}
        >
          <Page />
        </ProjectPage>
      );
    });
    it('should not show the project navigation', () => {
      const navbar = wrapper.find('ProjectNavbar');
      expect(navbar).to.have.lengthOf(0);
    });
    it('should not show any project announcements', () => {
      const announcement = wrapper.find('div.informational.project-announcement-banner');
      expect(announcement).to.have.lengthOf(0);
    });
    it('should not show the field guide', () => {
      const fieldguide = wrapper.find('PotentialFieldGuide');
      expect(fieldguide).to.have.lengthOf(0);
    });
  });

  describe('on other project pages', () => {
    let wrapper;
    beforeEach(() => {
      project.slug = 'test/project';
      project.configuration = {};
      project.configuration.announcement = 'This is a test announcement';
      const mockLocation = {
        pathname: `/projects/${project.slug}/about`
      };
      const routes = [];
      routes[2] = { path: 'about' };
      wrapper = shallow(
        <ProjectPage
          location={mockLocation}
          routes={routes}
          project={project}
        >
          <Page />
        </ProjectPage>
      );
    });
    it('should show the project navigation', () => {
      const navbar = wrapper.find('ProjectNavbar');
      expect(navbar).to.have.lengthOf(1);
    });
    it('should show any project announcements', () => {
      const announcement = wrapper.find('div.informational.project-announcement-banner');
      expect(announcement).to.have.lengthOf(1);
    });
    it('should show the field guide', () => {
      const fieldguide = wrapper.find('PotentialFieldGuide');
      expect(fieldguide).to.have.lengthOf(1);
    });
  });

  describe.only('sugar subscriptions', function() {
    const channel = `project-${project.id}`;
    const sugarClientMock = sinon.mock(sugarClient);
    let wrapper;

    // so this mock needs to be restored before each run
    beforeEach(() => {
      sugarClientMock.restore(); // Unwraps the mock
    });

    describe('on component lifecycle', function() {

      it('subscribes the user to the sugar project channel on mount', () => {
        sugarClientMock.expects('subscribeTo').once().withArgs(channel);
        wrapper = mount(
          <ProjectPage project={project}>
            <Page />
          </ProjectPage>
        );
      });

      it('unsubscribes the user from the sugar project channel on unmount', () => {
        wrapper = shallow(
          <ProjectPage project={project}>
            <Page />
          </ProjectPage>
        );
        sugarClientMock.expects('unsubscribeFrom').once().withArgs(channel);
        wrapper.unmount();
      });
    });

    describe('on project props change', function() {
      const newProject = {id: '999', title: 'fake project', slug: 'owner/name'};
      const newChannel = `project-${newProject.id}`;
      let wrapper;
      beforeEach(() => {
        wrapper = shallow(
          <ProjectPage project={project}>
            <Page />
          </ProjectPage>
        );
      });

      it('subscribes new project', () => {
        sugarClientMock.expects('subscribeTo').once().withArgs(newChannel);
        wrapper.setProps({ project: newProject });
      });

      it('unsubscribes old project', () => {
        sugarClientMock.expects('unsubscribeFrom').once().withArgs(channel);
        wrapper.setProps({ project: newProject });
      });
    });
  });
});
