// Variables
let isJobActive = false;

// Show/hide UI
function toggleUI(visible, jobActive = false) {
    if (visible) {
        $("#job-container").removeClass("hidden");
        updateJobStatus(jobActive);
    } else {
        $("#job-container").addClass("hidden");
    }
}

// Update job status display
function updateJobStatus(active) {
    isJobActive = active;
    
    if (active) {
        $("#duty-status").text("ON DUTY");
        $("#status-dot").addClass("active");
        $("#inactive-panel").addClass("hidden");
        $("#active-panel").removeClass("hidden");
    } else {
        $("#duty-status").text("OFF DUTY");
        $("#status-dot").removeClass("active");
        $("#inactive-panel").removeClass("hidden");
        $("#active-panel").addClass("hidden");
    }
}

// Update scene information
function updateSceneInfo(location) {
    $("#scene-location").text(location || "Unknown");
    $("#scene-status").text("Pending");
}

// Show notification
function showNotification(message, type = "info") {
    const notification = $(`<div class="notification ${type}">${message}</div>`);
    $("#notification-container").append(notification);
    
    // Remove notification after animation completes
    setTimeout(() => {
        notification.remove();
    }, 4000);
}

// Event listeners
$(document).ready(function() {
    // Close UI button
    $("#close-ui").click(function() {
        $.post("https://nrp-crimescenecleaner/closeUI", JSON.stringify({}));
    });
    
    // Start shift button
    $("#start-shift").click(function() {
        $.post("https://nrp-crimescenecleaner/startShift", JSON.stringify({}));
        showNotification("Starting shift...", "info");
    });
    
    // End shift button
    $("#end-shift").click(function() {
        $.post("https://nrp-crimescenecleaner/endShift", JSON.stringify({}));
        showNotification("Ending shift...", "info");
    });
});

// NUI message handler
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === "toggleUI") {
        toggleUI(data.show, data.jobActive);
    }
    
    if (data.action === "showJobInfo") {
        updateJobStatus(data.jobActive);
        
        if (data.currentScene) {
            updateSceneInfo(data.currentScene);
        }
    }
    
    if (data.action === "notification") {
        showNotification(data.message, data.type);
    }
});

// Close UI on escape key
document.onkeyup = function(data) {
    if (data.which == 27) { // ESC key
        $.post("https://nrp-crimescenecleaner/closeUI", JSON.stringify({}));
    }
};