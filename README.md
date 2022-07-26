<div align="center">
    <img src='https://user-images.githubusercontent.com/24974091/176677629-d683648a-ac6d-4614-bda3-f83ab219c235.png'></img><br>
    <strong>Ruby HTTP framework for reliable, concurrent and scalable applications</strong>
</div>

# About

Rubidium is an HTTP framework focused on a hierarchical and intuitive resource fetching model where each file is renderer based on its kind. This model allows a maintainable server structure and an abstracted file rendering process.

Standard services and utilities, some of them are not available yet
- [x] Server, it abstracts the process of comunication with clients and uses the middleware
- [x] Renderer, it's in charge of selecting a rederer for the request file and process it
- [x] File Cache, it reads the files from the hard disk and keep them in memory
- [x] Router, it maps the tracked folders and translates the http route into a file in disk
- [x] SQL Database Connector (currently PostgreSQL Connnector), it provides multiple connections to one database and handles sql queries
- [ ] Runtime Monitor, listen to commands at runtime for services maintenance

Those processes can comunicate among them using primitives exposed to the aplication with an unique name. The application module support launching processes from any of the services, besides its allows including services at the beggining of the application extending its functionalities.

# How to use it?

Clone the project
```
git clone https://github.com/albertoaer/rubidium.git
```

Launch it using rake
```
rake run
```

All the servicies and utilities are loaded into the application at [main.rb](./main.rb)

Public files served by the application server are located at [public](./public) folder

If you notice the lack of a renderer or want a custom one, add it to the [renderers](./lib/services/renderers) folder and `use` it at the Renderer in the [main](./main.rb) application file for an extension

## Features already included
- Routing system of mounted folders like *./public* and every subfolder of *./exposed*
- `PostgreSQL` database connection and queries
- `Template` rendering
- Ruby HTTP `Controllers`
- `Session` cookie
- Error handlers and redirections
- Early `PWA` support
- Configuration folder system called *Vault*
- `Cache` layers for fast response to parameterized requests
- Custom `Web Components` fully written in `Ruby` with Opal

## Features in progress for first release
- Built-in privacy system using session middleware and file system