import css from 'katex/dist/katex.css'
import katex from 'katex'

const target = document.getElementById('equation')
window.renderEquation = function(eq, size, display) {
    target.style.fontSize = size + "px"
    try {
        katex.render(eq, target, {
            displayMode: display
        })
    } catch (error) {
        webkit.messageHandlers.error.postMessage(1)
    }
    // Wait for the first font to load
    document.fonts.load('16px KaTeX_Main').then(_ => {
        // Then wait a little bit longer
        setTimeout(function() {
            const rect = target.getBoundingClientRect()  
            const dims = [rect.x, rect.y, rect.width, rect.height].map(Math.round).join(",")
            webkit.messageHandlers.renderDone.postMessage(dims)
        }, 1)
    })
}