let currentDays = 0;
const counterElement = document.getElementById('survival-counter');
const daysCountElement = document.getElementById('days-count');

// Función para actualizar el contador
function updateCounter(days) {
    if (days !== currentDays) {
        currentDays = days;
        daysCountElement.textContent = days;
        
        // Mostrar el contador si está oculto
        if (counterElement.classList.contains('hidden')) {
            counterElement.classList.remove('hidden');
        }
        
        // Animación al actualizar
        daysCountElement.classList.add('updated');
        setTimeout(() => {
            daysCountElement.classList.remove('updated');
        }, 500);
    }
}

// Función para ocultar el contador
function hideCounter() {
    counterElement.classList.add('hidden');
}

// Función para mostrar el contador
function showCounter() {
    counterElement.classList.remove('hidden');
}

// Escuchar mensajes del cliente
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'updateDays') {
        updateCounter(data.days);
    } else if (data.action === 'show') {
        showCounter();
    } else if (data.action === 'hide') {
        hideCounter();
    }
});

// Inicializar oculto
hideCounter();

