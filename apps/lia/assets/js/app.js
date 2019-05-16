// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import '../liascript/src/scss/main.scss';
//import css from "../css/app.scss";


//import "../liascript/src/scss/main.scss";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative paths, for example:


import socket from "./socket"

import { LiaScript } from "../liascript/src/javascript/liascript/index"

if(document.getElementById("lia")) {
    var app = new LiaScript(
      document.getElementById("lia"),
      false,
      null,
      null,
      "",
      0,
      true,
      socket.channel("lia:"));
} else {
    var app = null;
}
