class PoseWorker {
    constructor() {
        this.pose = null;
        this.onResultsCallback = null;
        this.video = null;
        this.isProcessing = false;
        this.frameCount = 0;
    }

    initialize(canvasElement, onResults) {
        console.log("PoseWorker: initialize called. Callback arg:", onResults);

        if (onResults) {
            this.onResultsCallback = onResults;
        } else {
            console.warn("PoseWorker: initialize called without callback! Relying on pre-set property.");
        }

        console.log("PoseWorker: Current callback:", this.onResultsCallback);
        console.log("PoseWorker: Initializing MediaPipe Pose...");

        try {
            if (this.pose) {
                this.pose.close(); // Cleanup old if exists
            }

            this.pose = new Pose({
                locateFile: (file) => {
                    return `https://cdn.jsdelivr.net/npm/@mediapipe/pose/${file}`;
                }
            });

            this.pose.setOptions({
                modelComplexity: 1,
                smoothLandmarks: true,
                enableSegmentation: false,
                minDetectionConfidence: 0.5,
                minTrackingConfidence: 0.5
            });

            this.pose.onResults(this.onResults.bind(this));
            console.log("PoseWorker: Initialized!");
        } catch (e) {
            console.error("PoseWorker: Initialization failed", e);
        }
    }

    async startCamera(videoElement) {
        console.log("PoseWorker: Starting Camera Loop...");
        this.video = videoElement;
        this.processLoop();
    }

    async processLoop() {
        if (!this.video || !this.pose) {
            requestAnimationFrame(() => this.processLoop());
            return;
        }

        // Check if video is ready
        if (this.video.readyState < 2) {
            // HAVE_CURRENT_DATA = 2
            requestAnimationFrame(() => this.processLoop());
            return;
        }

        if (!this.isProcessing) {
            this.isProcessing = true;
            try {
                // Diagnostic log every 100 frames
                if (this.frameCount % 100 === 0) {
                    // console.log(`PoseWorker: Processing frame ${this.frameCount}`);
                    // Check callback status periodically
                    if (!this.onResultsCallback) {
                        console.warn("PoseWorker: WARNING - onResultsCallback is MISSING!");
                    }
                }

                await this.pose.send({ image: this.video });
                this.frameCount++;
            } catch (e) {
                console.error("PoseWorker: Error processing frame", e);
            } finally {
                this.isProcessing = false;
            }
        }

        requestAnimationFrame(() => this.processLoop());
    }

    onResults(results) {
        // console.log("PoseWorker: onResults");
        if (results.poseLandmarks) {
            if (this.frameCount % 100 === 0) {
                console.log("PoseWorker: Landmarks detected!");
            }
            if (this.onResultsCallback) {
                // Limit log frequency
                if (this.frameCount % 50 === 0) {
                    console.log("PoseWorker: Calling Dart callback with", results.poseLandmarks.length, "landmarks");
                }
                this.onResultsCallback(results.poseLandmarks);
            } else {
                if (this.frameCount % 100 === 0) {
                    console.error("PoseWorker: Cannot call callback - it is NULL!");
                }
            }
        } else {
            if (this.frameCount % 100 === 0) {
                console.log("PoseWorker: No landmarks in result");
            }
        }
    }
}

// Ensure single instance if possible or replace logic
if (!window.poseWorker) {
    window.poseWorker = new PoseWorker();
} else {
    // If reloading script, maybe we want to keep the old one or replace?
    // For now replace.
    window.poseWorker = new PoseWorker();
    console.log("PoseWorker: Re-instantiated");
}
