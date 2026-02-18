---
description: Require UI mockups/storyboards before frontend implementation
---

# Spec-Driven Design Rule

## Core Principle
Before writing any frontend code, generate a visual specification (mockup or storyboard) for user approval.

## Workflow
1. **Receive UI requirement**
2. **Generate visual mockup** using Nano Banana Pro or design tool
3. **Present for approval** before implementation
4. **Implement** only after approval

## Creative Director Prompting
When generating design assets, use rich, descriptive prompts:

### Good Prompt Structure
```
Subject: [Detailed description of the main element]
Style: [Visual style - e.g., minimalist, glassmorphism, brutalist]
Composition: [Layout, spacing, visual hierarchy]
Materials: [Textures - e.g., "brushed steel", "frosted glass"]
Lighting: [Ambient, dramatic, soft shadows]
Color Palette: [Specific colors or mood]
Camera: [Angle if 3D - "low-angle shot", "isometric view"]
```

### Example Prompts
```
# Dashboard Card
"A modern analytics dashboard card with glassmorphism effect,
featuring a subtle gradient from deep purple (#6B46C1) to blue (#3B82F6),
soft drop shadows, rounded corners (16px), displaying a line chart
with smooth animations, clean sans-serif typography (Inter font)"

# Hero Section
"Wide-angle hero section with asymmetric layout, featuring large
bold headline on left (72px, weight 800), product mockup on right
with subtle float animation, gradient mesh background in warm
sunset tones (coral to peach), ample negative space"
```

## Exceptions
- Minor CSS fixes (colors, spacing)
- Bug fixes to existing UI
- Accessibility improvements to approved designs
