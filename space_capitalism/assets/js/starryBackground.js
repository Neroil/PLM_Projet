// Initialize starry background
function initStarryBackground() {
    const starsContainer = document.getElementById('stars-container');
    if (!starsContainer) return;

    const starCount = 250;

    // Create initial stars with positions across the screen
    for (let i = 0; i < starCount; i++) {
        createInitialStar(starsContainer);
    }

    // Loop creating new stars
    setInterval(() => {
        createNewStar(starsContainer);
    }, 300); // Create a new star every 300ms
}

// Function to create initial stars (distributed across the screen)
function createInitialStar(container) {
    const star = document.createElement('div');

    // Randomize star properties
    const size = Math.random();
    if (size < 0.6) {
        star.classList.add('star', 'star-small');
    } else if (size < 0.9) {
        star.classList.add('star', 'star-medium');
    } else {
        star.classList.add('star', 'star-large');
    }

    // For initial stars, position across entire screen
    const initialProgress = Math.random() * 100;
    star.style.left = `${initialProgress}vw`;
    star.style.top = `${Math.floor(Math.random() * 100)}%`;

    // Vary animation duration to create depth effect
    let duration;
    if (star.classList.contains('star-small')) {
        duration = 35 + Math.random() * 25; // Slower
    } else if (star.classList.contains('star-medium')) {
        duration = 25 + Math.random() * 20; // Medium speed
    } else {
        duration = 15 + Math.random() * 15; // Faster
    }

    star.style.animationDuration = `${duration}s`;

    // Calculate remaining animation time based on position
    const remainingDuration = duration * (1 - (initialProgress / 100));

    // Add star to container
    container.appendChild(star);

    // Remove after calculated remaining duration
    setTimeout(() => {
        star.remove();
    }, remainingDuration * 1000);
}

// Function to create new stars (always starting from left, outside viewport)
function createNewStar(container) {
    const star = document.createElement('div');

    // Randomize star properties
    const size = Math.random();
    if (size < 0.6) {
        star.classList.add('star', 'star-small');
    } else if (size < 0.9) {
        star.classList.add('star', 'star-medium');
    } else {
        star.classList.add('star', 'star-large');
    }

    // Always position new stars outside the viewport (left side)
    star.style.left = `-10px`;
    star.style.top = `${Math.floor(Math.random() * 100)}%`;

    // Vary animation duration to create depth effect
    let duration;
    if (star.classList.contains('star-small')) {
        duration = 35 + Math.random() * 25; // Slower
    } else if (star.classList.contains('star-medium')) {
        duration = 25 + Math.random() * 20; // Medium speed
    } else {
        duration = 15 + Math.random() * 15; // Faster
    }

    star.style.animationDuration = `${duration}s`;

    // Add star to container
    container.appendChild(star);

    // Remove star when animation completes
    setTimeout(() => {
        star.remove();
    }, duration * 1000);
}

// Initialize when document is loaded
document.addEventListener("DOMContentLoaded", initStarryBackground);