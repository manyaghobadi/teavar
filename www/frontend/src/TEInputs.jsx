import React, { Component } from 'react';
import styled from 'styled-components';

const StyledInputs = styled.div`
    form {
        margin: 10px;
        select {
         -webkit-appearance: button;
         -webkit-border-radius: 2px;
         -webkit-box-shadow: 0px 1px 3px rgba(0, 0, 0, 0.1);
         -webkit-padding-end: 20px;
         -webkit-padding-start: 2px;
         -webkit-user-select: none;
         background-image: url(http://i62.tinypic.com/15xvbd5.png), -webkit-linear-gradient(#FAFAFA, #F4F4F4 40%, #E5E5E5);
         background-position: 97% center;
         background-repeat: no-repeat;
         border: 1px solid #AAA;
         color: #555;
         font-size: inherit;
         overflow: hidden;
         padding: 5px 10px;
         text-overflow: ellipsis;
         white-space: nowrap;
         width: 370px;
        }
    }
    .input {
      text-align: center;
      width: 100%;
      display: block;
      height: 50px;

      select {
        border: none;
      }

      input, form {
        font-size: 20px;
        margin-left: 0;
        margin-right: 0;
        display: inline-block;
        border-left: none;
        border-right: 1px solid #AAA;
        border-top: 1px solid #AAA;
        border-bottom: 1px solid #AAA;
        border-top-left-radius: 0px;
        border-bottom-left-radius: 0px;
      }
    }

    .input_label {
      color: white;
      display: inline-block;
      width: 90px;
      height: calc(100% - 29px);
      background-color: #999;
      vertical-align: top;
      margin: 10px 0px;
      padding: 6px 10px;
      border-left: 1px solid #AAA;
      border-top: 1px solid #AAA;
      border-bottom: 1px solid #AAA;
      font-size: 18px;
    }

    input {
      position: relative;
      display: block;
      margin: 10px auto;
      -webkit-appearance: button;
      -webkit-border-radius: 2px;
      -webkit-box-shadow: 0px 1px 3px rgba(0, 0, 0, 0.1);
      -webkit-padding-end: 20px;
      -webkit-padding-start: 2px;
      -webkit-user-select: none;
      border: 1px solid #AAA;
      color: #555;
      font-size: inherit;
      overflow: hidden;
      padding: 5px 10px;
      text-overflow: ellipsis;
      white-space: nowrap;
      width: 350px;
    }
    button {
      margin: 10px;
      font-size: 20px;
    }
`;

class TEInputs extends Component {
    render() {
        return (
          <div>
            <StyledInputs>
              <div className="input">
                  <div className="input_label">Topology</div>
                  <form>
                  <select name="dropdown" onChange={e => this.props.handleTEInput(e.target.value, "topology")}>
                      <option value="Custom" default>Small Net</option>
                      <option value="B4">B4</option>
                      <option value="IBM">IBM</option>
                      <option value="Abilene">Abilene</option>
                  </select>
                  </form>
                </div>              
              <div className="input">
                  <div className="input_label">Demand</div>
                  <form>
                  <select name="dropdown" onChange={e => this.props.handleTEInput(e.target.value, "demand")}>
                      <option value="1" default>1</option>
                      <option value="2">2</option>
                      <option value="3">3</option>
                      <option value="4">4</option>
                      <option value="5">5</option>
                      <option value="6">6</option>
                  </select>
                </form>
              </div>
              <div className="input">
                  <div className="input_label">Paths</div>
                  <form>
                  <select name="dropdown" onChange={e => this.props.handleTEInput(e.target.value, "path")}>
                      <option value="ED" default>ED</option>
                      <option value="SMORE">Oblivious</option>
                      <option value="ksp_2">KSP_2</option>
                      <option value="ksp_4">KSP_4</option>
                      <option value="ksp_6">KSP_6</option>
                  </select>
                </form>
              </div>
              <div className="input">
                <div className="input_label">Beta (%)</div>
                <input
                  type="text"
                  placeholder="0.9"
                  onChange={e => this.props.handleTEInput(e.target.value, "beta")}
                />
              </div>
              <div className="input">
                <div className="input_label">Cutoff (%)</div>
                <input
                  type="text"
                  placeholder="0.0001"
                  onChange={e => this.props.handleTEInput(e.target.value, "cutoff")}
                />
              </div>
              <button onClick={e => this.props.handleTESubmit()}>
                Submit
              </button>
            </StyledInputs>
          </div>
        );
    }
}

export default TEInputs;
