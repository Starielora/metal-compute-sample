#define GLFW_INCLUDE_NONE
#define GLFW_EXPOSE_NATIVE_COCOA
#include <GLFW/glfw3.h>
#include <GLFW/glfw3native.h>

#include <iostream>

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

void quit(GLFWwindow *window, int key, int scancode, int action, int mods);
GLFWwindow* createWindow(CAMetalLayer* metalLayer);
CAMetalLayer* createMetalLayer(id<MTLDevice> gpu);
id<MTLComputePipelineState> createPipelineState(id<MTLDevice> gpu);

int main()
{
    const id<MTLDevice> gpu = MTLCreateSystemDefaultDevice();
    const id<MTLCommandQueue> queue = [gpu newCommandQueue];
    auto* const metalLayer = createMetalLayer(gpu);
    auto* const window = createWindow(metalLayer);
    auto* const computePipelineState = createPipelineState(gpu);

    metalLayer.framebufferOnly = false;

    while (!glfwWindowShouldClose(window))
    {
        glfwPollEvents();

        @autoreleasepool {
            id<CAMetalDrawable> surface = [metalLayer nextDrawable];
            auto commandBuffer = [queue commandBuffer];
            auto computeEncoder = [commandBuffer computeCommandEncoder];
            [computeEncoder setComputePipelineState:computePipelineState];
            [computeEncoder setTexture:surface.texture atIndex:0];
            auto width = computePipelineState.threadExecutionWidth;
            auto height = computePipelineState.maxTotalThreadsPerThreadgroup / width;
            auto threadsPerGroup = MTLSizeMake(width, height, 1);
            auto threadsPerGrid = MTLSizeMake(metalLayer.drawableSize.width, metalLayer.drawableSize.height, 1);

            [computeEncoder dispatchThreads:threadsPerGrid threadsPerThreadgroup:threadsPerGroup];
            [computeEncoder endEncoding];
            [commandBuffer presentDrawable:surface];
            [commandBuffer commit];
        }
    }

    glfwDestroyWindow(window);
    glfwTerminate();
    return EXIT_SUCCESS;
}

void quit(GLFWwindow *window, int key, int scancode, int action, int mods)
{
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
        glfwSetWindowShouldClose(window, GLFW_TRUE);
    }
}

GLFWwindow* createWindow(CAMetalLayer* metalLayer)
{
    if (glfwInit() != GLFW_TRUE)
    {
        std::cerr << "Failed to init glfw.\n";
        exit(EXIT_FAILURE);
    }

    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);

    const auto window = glfwCreateWindow(800, 800, "metal-compute-sample", nullptr, nullptr);

    if (window == nullptr)
    {
        glfwTerminate();
        std::cerr << "Failed to create window.\n";
        exit(EXIT_FAILURE);
    }

    glfwSetKeyCallback(window, quit);

    NSWindow* nswindow = glfwGetCocoaWindow(window);
    // Could assign MTKView here, but GLFW implements its own NSView which handles keyboard and mouse events
    nswindow.contentView.layer = metalLayer;
    nswindow.contentView.wantsLayer = YES;

    return window;
}

CAMetalLayer* createMetalLayer(id<MTLDevice> gpu)
{
    CAMetalLayer *swapchain = [CAMetalLayer layer];
    swapchain.device = gpu;
    swapchain.opaque = YES;

    return swapchain;
}

id<MTLComputePipelineState> createPipelineState(id<MTLDevice> gpu)
{
    NSError* errors;
    id<MTLLibrary> library = [gpu newLibraryWithFile:@"default.metallib" error:&errors];
    assert(!errors);

    id<MTLFunction> function = [library newFunctionWithName:@"compute"];

    auto pipelineState = [gpu newComputePipelineStateWithFunction:function error:&errors];
    assert(!errors);

    return pipelineState;
}
