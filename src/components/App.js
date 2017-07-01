import React, { Component } from 'react';
import PropTypes from 'prop-types';
import DrawableCanvas from './DrawingCanvas';
import Prediction from './Prediction.js'
import '../assets/styles/App.scss';


class App extends Component {
  constructor() {
    super();

    this.state = {
      canvas: null,
      ctx: null,
      prediction: ''
    };

    this.submit = this.submit.bind(this);
    this.clear = this.clear.bind(this);
  }

  componentDidMount() {
    let can = document.getElementById('canvas');

    this.setState({
      canvas: can,
      ctx: can.getContext('2d')
    });
  }

  clear() {
    let canvasClear = this.refs.editableCanvas.clear;
    canvasClear();
  }

  submit() {
    this.setState({
      prediction: '...'
    });

    fetch('/predict', {
      method: 'POST',
      body: this.state.canvas.toDataURL('image/png')
    }).then(response => {
      return response.json();
    }).then(j => {
      this.setState({
        prediction: j.prediction
      });
    });
  }

  render() {
    return (
      <div>
        <DrawableCanvas />
        <Prediction value={ this.state.prediction } />
        <button onClick={this.submit}> Submit </button>
      </div>
    );
  }
};

App.propTypes = {
  name: PropTypes.string,
};

export default App;
