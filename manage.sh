#!/bin/bash

# Change to the script's directory
cd "$(dirname "$0")"

IMAGE_NAME="${LAYA_DOCKER_REPO:-vinaybalamuru/laya}"
IMAGE_TAG="${LAYA_DOCKER_TAG:-cuda}"
TORCH_INDEX="${LAYA_TORCH_INDEX:-cu130}"
TORCH_VERSION="${LAYA_TORCH_VERSION:-2.14.0}"
COMPOSE_FILE="docker-compose/docker-compose.yml"
IS_INTERACTIVE=0

show_menu() {
    clear
    echo "========================================"
    echo "       Laya CUDA Image Management"
    echo "========================================"
    echo "Target: ${IMAGE_NAME}:${IMAGE_TAG}"
    echo ""
    echo "1. Build CUDA Image"
    echo "2. Build & Push to Docker Hub"
    echo "3. Push to Docker Hub"
    echo "4. Run CUDA Quickstart (docker compose run)"
    echo "5. Start HTTP Server (Background)"
    echo "6. Stop Stack (docker compose down)"
    echo "7. View Logs"
    echo "8. Test CUDA GPU in Container"
    echo "9. Exit"
    echo ""
    read -p "Enter your choice (1-9): " choice

    IS_INTERACTIVE=1
    case $choice in
        1) build_image ;;
        2) build_and_push ;;
        3) push_image ;;
        4) run_quickstart ;;
        5) start_server ;;
        6) stop_stack ;;
        7) view_logs ;;
        8) test_cuda ;;
        9) exit 0 ;;
        *)
            echo ""
            echo "Invalid choice. Please try again."
            read -p "Press enter to continue..."
            show_menu
            ;;
    esac
}

pause_and_menu() {
    if [ "$IS_INTERACTIVE" -eq 1 ]; then
        echo ""
        read -p "Press enter to continue..."
        show_menu
    fi
}

build_image() {
    echo ""
    echo "Building CUDA image (${IMAGE_NAME}:${IMAGE_TAG})..."
    docker build \
        --build-arg TORCH_INDEX="$TORCH_INDEX" \
        --build-arg TORCH_VERSION="$TORCH_VERSION" \
        -t "${IMAGE_NAME}:${IMAGE_TAG}" \
        .
    if [ $? -eq 0 ]; then
        echo ""
        echo "Image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"
    else
        echo ""
        echo "Build failed!"
    fi
    pause_and_menu
}

build_and_push() {
    echo ""
    echo "Building CUDA image (${IMAGE_NAME}:${IMAGE_TAG})..."
    docker build \
        --build-arg TORCH_INDEX="$TORCH_INDEX" \
        --build-arg TORCH_VERSION="$TORCH_VERSION" \
        -t "${IMAGE_NAME}:${IMAGE_TAG}" \
        .
    if [ $? -ne 0 ]; then
        echo ""
        echo "Build failed!"
        pause_and_menu
        return
    fi

    echo ""
    echo "Pushing ${IMAGE_NAME}:${IMAGE_TAG} to Docker Hub..."
    docker push "${IMAGE_NAME}:${IMAGE_TAG}"
    if [ $? -eq 0 ]; then
        echo ""
        echo "Successfully built and pushed ${IMAGE_NAME}:${IMAGE_TAG}!"
    else
        echo ""
        echo "Push failed! Make sure you are logged in (docker login)."
    fi
    pause_and_menu
}

push_image() {
    echo ""
    echo "Pushing ${IMAGE_NAME}:${IMAGE_TAG} to Docker Hub..."
    docker push "${IMAGE_NAME}:${IMAGE_TAG}"
    if [ $? -eq 0 ]; then
        echo ""
        echo "Successfully pushed ${IMAGE_NAME}:${IMAGE_TAG}!"
    else
        echo ""
        echo "Push failed! Make sure you are logged in (docker login)."
    fi
    pause_and_menu
}

run_quickstart() {
    echo ""
    echo "Running CUDA quickstart via Docker Compose..."
    docker compose -f "$COMPOSE_FILE" run --rm laya
    pause_and_menu
}

start_server() {
    echo ""
    echo "Starting laya-serve in background on port 8000..."
    docker compose -f "$COMPOSE_FILE" up -d laya-serve
    echo ""
    echo "Server started! Health endpoint: http://localhost:8000/health"
    pause_and_menu
}

stop_stack() {
    echo ""
    echo "Stopping stack..."
    docker compose -f "$COMPOSE_FILE" down
    echo ""
    echo "Stack stopped."
    pause_and_menu
}

view_logs() {
    echo ""
    echo "Streaming logs (Press Ctrl+C to exit)..."
    docker compose -f "$COMPOSE_FILE" logs -f laya-serve
    pause_and_menu
}

test_cuda() {
    echo ""
    echo "Testing CUDA availability inside container (${IMAGE_NAME}:${IMAGE_TAG})..."
    docker run --rm --gpus all "${IMAGE_NAME}:${IMAGE_TAG}" python -c \
        'import torch; assert torch.cuda.is_available(), "CUDA unavailable"; print("GPU detected:", torch.cuda.get_device_name(0)); print("CUDA tensor:", torch.ones(1, device="cuda").cpu())'
    pause_and_menu
}

# CLI Argument Handler
case "${1:-}" in
    build)
        build_image
        ;;
    build-and-push|bap)
        build_and_push
        ;;
    push)
        push_image
        ;;
    run)
        run_quickstart
        ;;
    start|up)
        start_server
        ;;
    stop|down)
        stop_stack
        ;;
    logs)
        view_logs
        ;;
    test)
        test_cuda
        ;;
    *)
        show_menu
        ;;
esac
