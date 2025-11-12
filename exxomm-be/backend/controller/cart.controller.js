const Cart = require('../models/Cart')
const { sendResponseError } = require('../middleware/middleware.js')

const getCartProducts = async (req, res) => {
  try {

    if (!req.user) {
      return res.status(200).send({ status: 'ok', carts: [] })
    }

    const carts = await Cart.find({userId: req.user._id}).populate('productId')
    // console.log(carts)
    res.status(200).send({status: 'ok', carts})
  } catch (err) {
    console.log(err)
    sendResponseError(500, `Error ${err}`, res)
  }
}

const addProductInCart = async (req, res) => {
  const {productId, count} = req.body
  try {

    if (!req.user) {
      return sendResponseError(
        401,
        'Unauthorized, please log in to add to cart',
        res,
      )
    }

    const cart = await Cart.findOneAndUpdate(
      {productId, userId: req.user._id},
      {productId, count, userId: req.user._id},
      {upsert: true, new: true},
    )

    res.status(201).send({status: 'ok', cart})
  } catch (err) {
    console.log(err)
    sendResponseError(500, `Error ${err}`, res)
  }
}
const deleteProductInCart = async (req, res) => {
  try {

    if (!req.user) {
      return sendResponseError(401, 'Unauthorized', res)
    }

    const deletedItem = await Cart.findByIdAndRemove(req.params.id, {
      _id: req.params.id,
      userId: req.user._id,
    });

    if (!deletedItem) {
      return sendResponseError(404, 'Cart item not found', res)
    }

    res.status(200).send({status: 'ok'})
  } catch (e) {
    console.log(err)
    sendResponseError(500, `Error ${err}`, res)
  }
}
module.exports = {addProductInCart, deleteProductInCart, getCartProducts}
