// INTENTIONALLY VULNERABLE — DO NOT DEPLOY
const { exec } = require("node:child_process");

function renderUserBanner(name) {
  return `<div class="banner">Welcome ${name}</div>`; // XSS if rendered unescaped
}

function pingHost(host, cb) {
  exec(`ping -c 1 ${host}`, cb); // OS command injection
}

module.exports = { renderUserBanner, pingHost };

