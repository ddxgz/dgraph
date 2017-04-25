import React from 'react';
import classnames from 'classnames';

import GraphContainer from "../containers/GraphContainer";

const SessionGraphTab = ({ session, active }) => {
  return (
    <div className={classnames('content-container', { hidden: !active})}>
      <GraphContainer
        response={session.response}
      />
    </div>
  );
};

export default SessionGraphTab;
