<div align="center">
    <h1>Rubidium</h1>
    <strong>Ruby HTTP framework for reliable, concurrent and scalable applications</strong>
</div>

# About

Rubidium is an HTTP framework focused on a hierarchical and intuitive resource fetching model where each file is renderer based on its kind. This model allows a maintainable server structure and an abstracted file rendering process.

An application must have at least 3 services
- Server, that abstract the process of comunication with clients
- Renderer, in charge of selecting a rederer for the request file and process it
- File Inspector, provides files from the hard disk and allows some kind of policy to maintain them in memory
  
Those processes can comunicate among them using primitives exposed to the aplication with an unique name. The application module support launching processes from any of the services, besides its allows including services at the beggining of the application extending its functionalities.

# How to use it?

Clone the project
```
git clone https://github.com/albertoaer/rubidium.git
```

Application implementation is written at [main.rb](./main.rb)

Public files will be located at [public](./public) folder

If you want a custom renderer, add it to the [renderers](./lib/renderers) folder and `use` it at the Renderer in the [main](./main.rb) application file