# Maurice

**Maurice** is a static website generator made with Dart.

You can generate a static blog ready to be deployed in just a few commands. It's easy and minimalist.  
It supports :

- sitemap
- RSS feed
- pagination
- page generation for each resource (article, product, project...)

## How to install it

`dart pub global activate maurice`

## The concept

**Maurice** is using 2 kind of object : `page` and `resource`

A `page` is some HTML code that the tool will use to generate the final HTML pages.

A `resource` is a markdown file that contains data to populate a page. For instance, you can have the resource `article`, `product`, `employee`...

The resources are more or less a file database. I choose to not use a SQLite databse because I want the data to be easy to edit and create.

A page can use a resource to generate its content. Thanks to some configuration, you can define if a page will paginate the resources or if it generates a page for each item.

Both objects follow the same format. The first block contains configuration and variables injected to the templater and a second block that's contains either markdown or HTML.


## How to use

`maurice create <path>` : create a new project

`maurice resource new <resource name>` : create a new kind of resource

`maurice resource publish <resource id>` : make the resource visible

`maurice page new` : create a new page

`maurice build` : build the project into a full html website into the `output` folder 

## The routing

Maurice uses a folder-structure to generate the routes. For instances, the page `pages/articles/1.html` will be reached on the URL `http://website.com/articles/1.html`.  
The pages must be stored in the `pages` folder.

You are free to move the pages into the subfolders you want. Maurice will regenerate your website, the sitemap and RSS feed accordingly.

What happens during the generation :

- page without resources : It generates the page at the same level with the same title

- pagination : It generates a folder called `pages` at the same level than the page. Then the `pages` folder will contains pages named `1.html`, `2.html` etc...

- page per resource item : It generates all pages in the same folder

