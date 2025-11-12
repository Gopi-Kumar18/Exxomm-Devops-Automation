const JWT = {
  jwt: process.env.JWT_SECRET,
  jwtExp: '100d',
}
// console.log("JWT Secret:", JWT.jwt);
module.exports = {JWT}
