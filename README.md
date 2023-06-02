# godot-infinite-worldmap - A Procedural World Map Generator and Viewer Component

## Overview

The Procedural World Map Generator and Viewer Component is a powerful tool designed for game developers using the Godot 4 game engine. Its main purpose is to provide a fast and efficient way to generate and view procedurally generated world maps for game prototyping. This component offers a world generator and a high-performance viewer, enabling real-time navigation and zooming within the generated maps. It also supports progressive rendering, similar to Blender's internal renderer, allowing for quick low-quality rendering during map browsing and higher-quality rendering during idle periods.

## Features

- Procedural world generation: The component includes a core for implementing custom world generators. It also provides a basic world generator using the FastNoiseLite generator, which can be easily customized by adjusting the seed and coordinates.
- Fast and efficient rendering: The viewer is optimized for high-speed rendering, ensuring smooth navigation through the generated maps without any performance degradation.
- Zooming capability: The viewer allows users to zoom in and out of the maps, providing detailed exploration at various levels of magnification.
- Production-ready usage: With a custom renderer implementation, the component can be utilized for production purposes, enabling the generation of elaborate and visually appealing maps. It can even display pre-rendered maps.
- Versatile map generation: The convenience of the map generator offers a wide range of possibilities. By adjusting the seed and coordinates, developers can obtain completely different maps, making it easy to experiment until finding the desired starting point for their game. Additionally, it can be used to quickly generate world maps where the game takes place in specific areas, with the component filling in the gaps between those areas.
- Infinite zoom capability: Since the component is natively procedural, it allows for nearly infinite zooming within the limits of the implemented world generator. However, it's important to note that FastNoiseLite has its own limitations, as the quality of noise deteriorates when rendering far from the initial 0,0 coordinates.

## Getting Started

### Prerequisites

- Godot 4 game engine (version 4.0.3 or later)

### Installation

1. Download the Procedural World Map Generator and Viewer Component from the project repository.
2. Extract the component files to your Godot project directory.

### Usage

1. Open your Godot project and navigate to the desired scene where you want to incorporate the procedural world map generator and viewer component.
2. Import the component files into your scene.
3. Add the procedural world map generator and viewer component to the scene by creating a new instance or attaching it to an existing node.
4. Customize the world generator parameters or use the provided basic world generator using FastNoiseLite.
5. Run the scene to visualize the generated world map.
6. Explore the map by using the intuitive navigation controls, including zooming in and out.

### Examples

The component repository includes examples demonstrating how to utilize the procedural world map generator and viewer. These examples cover basic usage scenarios, customizing the world generator, and implementing a custom renderer. You can find the examples in the `examples/` directory.

## Customization

### Custom World Generator

To create a custom world generator, follow these steps:

1. Inherit the `WorldGenerator` class provided by the component.
2. Override the `generateMap()` method to implement your custom map generation logic.
3. Customize the parameters, such as noise functions and seed, to achieve the desired result.
4. Attach your custom world generator to the procedural world map generator and viewer component instance.

Refer to the example files (`examples/custom_world_generator.gd`) for a detailed guide on implementing a custom world generator.

```mermaid
flowchart TD;
    subgraph direct render
    init((( )))-->_ready--> FR[start fast render];
    refresh-->reset[stop all ongoing rendering]-->FR
    FR--"set lowest resolution
    image_changed=true"-->R[render task]
    end
    R-.->_process
    subgraph incremental rendering
    _process--image_changed=false-->TO[start timeout]-->IR[start incremental render]
    IR--increase resolution from lowest-->R2[threaded render task]
    R2-->RII{is cancelled?}-->RIIY[yes, replace texture] & RIIN[no]-->RHighestRes{is highest resolution?}
    RHighestRes-->Rcontinue[no] & RStop[yes]
    Rcontinue-->RCD["call deferred next render"]--increase resolution-->R2
    RStop--image_changed=false-->RFinished["Rendering finished"]
    end
```


### Custom Renderer

To implement a custom renderer for production purposes, follow these steps:

1. Inherit the `WorldRenderer`

 class provided by the component.
2. Override the `renderMap()` method to implement your custom rendering logic.
3. Customize the rendering process based on your specific requirements, such as texture mapping, lighting, or advanced visual effects.
4. Attach your custom renderer to the procedural world map generator and viewer component instance.

Refer to the example files (`examples/custom_renderer.gd`) for a detailed guide on implementing a custom renderer.

## Limitations

- The component is entirely written in GDScript 2 and doesn't require a powerful GPU.
- The quality of noise generated by the FastNoiseLite generator deteriorates when rendering far from the initial 0,0 coordinates. Keep this in mind when designing large-scale maps.

## Support and Contributions

For any questions, issues, or feature requests, please visit the project repository on GitHub: [link_to_repository](https://github.com/your/project/repository)

Contributions to the project are welcome. If you encounter any bugs, feel free to submit an issue on the repository page. If you have implemented improvements or new features, please open a pull request, and we'll review it as soon as possible.

## License

This component is released under the [MIT License](https://opensource.org/licenses/MIT). See the `LICENSE` file for more details.

## Acknowledgements

We would like to express our gratitude to the contributors and developers who have helped in the development of this component. Their efforts and support have made this project possible.

Special thanks to the creators of Godot 4 for providing a powerful and flexible game engine that allows developers to bring their ideas to life.
