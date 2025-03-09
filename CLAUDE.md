# CLAUDE.md - AI Assistant Guidelines

## Run Commands
- Run fractal visualization: `love fractal/`
- Run particle simulation: `love particle-simulation-visualizer/`

## Code Style Guidelines
- **Naming**: camelCase for functions/variables, UPPERCASE for constants
- **Variables**: Use `local` declarations, group related state variables
- **Functions**: Follow LÖVE2D lifecycle patterns (load, update, draw)
- **Organization**: Separate concerns, group related functionality
- **Formatting**: 4-space indentation, blank lines between logical blocks
- **Error Handling**: Use defensive programming, validate input/state
- **Comments**: Add descriptive headers and explain complex logic
- **Imports**: Simple require statements for modules
- **Objects**: Consistent table structures with predictable properties

## Project Structure
- `/fractal` - Fractal visualization
- `/particle-simulation-visualizer` - Particle simulation with QuadTree

This project uses the LÖVE2D framework for creating interactive visualizations.