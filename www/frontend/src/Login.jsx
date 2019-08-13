import React, { Component } from 'react';
import styled from 'styled-components';

const StyledLogin = styled.div`
    margin-top: 30vh;
`;

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
         width: 300px;
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

      .input-elt {
        font-size: 15px;
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
      width: 75px;
      height: calc(100% - 34px);
      background-color: #999;
      vertical-align: top;
      margin: 10px 0px;
      padding: 6px 10px;
      border-left: 1px solid #AAA;
      border-top: 1px solid #AAA;
      border-bottom: 1px solid #AAA;
      font-size: 14px;
    }

    .input-elt {
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
      width: 278px;
    }
    .button {
        color: white;
        display: block;
        width: 75px;
        background-color: #999;
        vertical-align: top;
        margin: 10px auto;
        padding: 6px 10px;
        border-left: 1px solid #AAA;
        border-top: 1px solid #AAA;
        border-bottom: 1px solid #AAA;
        font-size: 14px;
        border-radius: 5px;
    }
`;

class Login extends Component {
    constructor(props) {
        super(props);
        this.state = {
            password: "",
        }
    }

    handlePassword(v) {
        this.setState({
            password: v,
        })
    }
    render() {
        return (
          <StyledLogin>
            <StyledInputs id="login-window">
              <form className="input">
                {/* <div className="input_label">Password</div> */}
                <input
                  className="input-elt"
                  type="password"
                  placeholder=""
                  onChange={e => this.handlePassword(e.target.value)}
                />
                <input
                    className="button"
                    type="submit"
                    onClick={e => this.props.login(this.state.password)}
                    value="Login"
                />
              </form>

            </StyledInputs>
          </StyledLogin>
        );
    }
}

export default Login;
