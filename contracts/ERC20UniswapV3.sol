// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity = 0.8.20;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

contract SwapExamples {

    ISwapRouter public immutable swapRouter;

    uint24 public constant poolFee = 3000;

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    function swapExactInputSingle(address tokenInAddress, address tokenOutAddress, uint256 amountIn) external returns (uint256 amountOut) {
        // msg.sender must approve this contract

        // Transfer the specified amount of input token to this contract.
        TransferHelper.safeTransferFrom(tokenInAddress, msg.sender, address(this), amountIn);
        // Approve the router to spend DAI.
        TransferHelper.safeApprove(tokenInAddress, address(swapRouter), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenInAddress,
                tokenOut: tokenOutAddress,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    function swapExactOutputSingle(address tokenInAddress, address tokenOutAddress, uint256 amountOut, uint256 amountInMaximum) external returns (uint256 amountIn) {
        
        // Transfer the specified amount of DAI to this contract.
        TransferHelper.safeTransferFrom(tokenInAddress, msg.sender, address(this), amountInMaximum);

        // Approve the router to spend the specified `amountInMaximum` of DAI.
        // In production, you should choose the maximum amount to spend based on oracles or other data sources to achieve a better swap.
        TransferHelper.safeApprove(tokenInAddress, address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: tokenInAddress,
                tokenOut: tokenOutAddress,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = swapRouter.exactOutputSingle(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(tokenInAddress, address(swapRouter), 0);
            TransferHelper.safeTransfer(tokenInAddress, msg.sender, amountInMaximum - amountIn);
        }
    }
}