<svg width="200" height="200" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="ydot">
  <title>ydot</title>
  <desc>Geometric y mark with a floating dot representing dotfiles</desc>

  <g fill="none" stroke="{{text}}" stroke-width="13" stroke-linecap="round" stroke-linejoin="round">
    <!-- left arm of the y -->
    <path d="M27 17 L50 48"/>
    <!-- stem of the y -->
    <path d="M50 48 L50 83"/>
    <!-- right arm, cut short so the dot completes it -->
    <path d="M50 48 L60 33"/>
  </g>

  <!-- floating dot: the "dotfiles" hook, completes the right arm -->
  <circle cx="76" cy="16" r="11" fill="{{blue}}"/>
</svg>
