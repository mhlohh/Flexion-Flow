// web/pose_worker.js
class PoseWorker {
    constructor() {
        this.pose = null;
        this.camera = null;
        this.onResultsCallback = null;
    }

    initialize(canvasElement, onResults) {
        this.onResultsCallback = onResults;

        this.pose = new Pose({
            locateFile: (file) => {
                return `https://cdn.jsdelivr.net/npm/@mediapipe/pose/${file}`;
            }
        });

        this.pose.setOptions({
            modelComplexity: 1,
            smoothLandmarks: true,
            enableSegmentation: false,
            smoothSegmentation: false,
            minDetectionConfidence: 0.5,
            minTrackingConfidence: 0.5
        });

        this.pose.onResults(this.onResults.bind(this));
    }

    async startCamera(videoElement) {
        if (!this.pose) {
            console.error("PoseWorker not initialized");
            return;
        }

        this.camera = new Camera(videoElement, {
            onFrame: async () => {
                await this.pose.send({ image: videoElement });
            },
            width: 640,
            height: 480
        });

        await this.camera.start();
    }

    onResults(results) {
        if (this.onResultsCallback && results.poseLandmarks) {
            // Convert landmarks to simple array or keep as object
            // We pass the raw array of objects back to Dart
            this.onResultsCallback(results.poseLandmarks);
        }
    }
}

window.poseWorker = new PoseWorker();
