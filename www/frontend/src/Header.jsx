import React, { Component } from 'react';
import styled from 'styled-components';

const StyledHeader = styled.div`
    position: fixed;
    height: 67px;
    width: 100vw;
    top: 0;
    border-bottom: 1px solid #222;
    box-shadow: 0 1px 0 #262626;
    background-color: #191919;
    background-image: -webkit-gradient(linear,left top,left bottom,from(#282828),to(#191919));
    background-image: -webkit-linear-gradient(top,#282828,#191919);
    background-image: linear-gradient(top,#282828,#191919);
    background-repeat: no-repeat;
    z-index: 10;

    #left {
        position: absolute;
        height: 100%;
        left: 10px;
    }

    #center {
        position: absolute;
        height: 100%;
        left: 50%;
        transform: translateX(-50%);
        color: white;

        #title {
            font-size: 25px;
            padding-top: 15px;
        }
    }

    #right {
        position: absolute;
        height: 100%;
        padding-top: 20px;
        padding-right: 20px;
        right: 10px;
        color: white;

        .link {
            cursor: pointer;
            &:hover {
                border-bottom: 1px solid white;
            }
        }
    }
`;


class Header extends Component {
  render() {
    let modes = this.props.modes.map((mode, num) => {
        return this.props.mode === mode ? "" :
            <div key={num} className="link" onClick={e => this.props.setMode(mode)}>{mode}</div>
    })
    return (
      <div>
        <StyledHeader>
            <div id="left">
            </div>
            <div id="center">
                <div id="title">
                    TEAVAR Demo
                </div>
            </div>
            <div id="right">
                {modes}
            </div>
        </StyledHeader>
      </div>
    );
  }
}

export default Header;
