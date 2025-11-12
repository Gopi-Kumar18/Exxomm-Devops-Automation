const bcrypt = require('bcrypt')
const jwt = require('jsonwebtoken')
const {JWT} = require('../config/config')
const checkPassword = (password, passwordHash) => {
  return new Promise((resolve, reject) => {
    bcrypt.compare(password, passwordHash, (err, same) => {
      if (err) {
        reject(err)
      }

      resolve(same)
    })
  })
}


const newToken = user => {
  return jwt.sign({id: user._id}, JWT.jwt, {
    expiresIn: JWT.jwtExp,
  })
}

const verifyToken = token =>
  new Promise((resolve, reject) => {

     console.log("Token received for verification:", token);

      console.log("JWT Secret being used:", JWT.jwt);

      if (!token) {
      return reject(new Error("No token provided"));
    }

    jwt.verify(token, JWT.jwt, (err, payload) => {
      if (err) {
        console.error("JWT verification error:", err.message);
        return reject(err)
      } 
      console.log("JWT payload after verification:", payload);
      resolve(payload)
    })
  })

module.exports = {checkPassword, newToken, verifyToken}
