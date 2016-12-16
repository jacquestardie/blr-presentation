
Raster processing on the command-line
=====================================

A short introduction to raster processing using command line tools.

#### Requirements

We'll be using the following Python packages, all of which can be installed via `pip`.

```
landsat-util 
fiona 
rasterio 
rio-color 
mapbox-cli-py
```

These packages will each require an additional set of dependencies, installation of which will differ across platforms. Rather than spending time dealing each package's dependencies installed correctly, I recommend that you instead use the prebuilt Docker image which which should contain all the packages we'll use.

#### Via Docker

First, you'll need to [download and install Docker](https://www.docker.com/products/overview). Once Docker is configured, you can go ahead and pull down the image we've built for this tutorial.

```
docker pull jacquestardie/blr-presentation:latest
```

Once we've downloaded the Docker image, we can run it via:

```
docker run --volume $(pwd):/data -it blr-presentation:latest /bin/bash
```

This will mount the local directory `$(pwd)` on your own machine, to the `/data` directory within the Docker container. In other words, any files you create in `/data` will also be accessible locally.

We'll need to do one last thing in order to get access to the packages which we'll be using.

```
source /tmp/venv/bin/activate
cd /data
```

Getting started
---------------

The first thing we'll need to do is acquire some Landsat imagery. We've got a few flash drives to pass around which contain imagery collected over Bangalore.

My favorite way to search around for Landsat imagery is via Vincent Sarago's [SatelliteSearch](https://remotepixel.ca/projects/satellitesearch.html). The Landsat path & row which encompasses Bangalore is `144, 51`, which is what we'll be working with today.

Let's see what imagery is available. We can use the `landsat` package here, to filter for the path and row, as well as the maximum amount of cloud coverage.

```
landsat search --pathrow 144,51 --cloud 10
```

The `LC81440512016096LGN00` scene looks promising, let's download it.

```
landsat download LC81440512016096LGN00 -d . -b2,3,4
```

We can investigate our imagery's metadata using `rio`.

```
rio info --indent 4 /data/LC81440512016096LGN00/LC81440512016096LGN00_B4.TIF 
```

Next, we're going to need to turn the individual images into a single RGB image.

```
landsat process /data/LC81440512016096LGN00 --bands 432
mv /root/landsat/processed/LC81440512016336LGN00/LC81440512016336LGN00_bands_432.TIF 432.TIF
```

Let's take a look at metadata for our new image. 

What we have is great, but it's a bit more information than we need. Let's clip this imagery to the city of Bangalore. I like to use [geojson.io](http://geojson.io/#map=9/12.8198/77.5745) to draw boundaries. You can easily export the bounds as a `geojson`, which is what we'll use to clip our Landsat imagery with.

![](https://cldup.com/u_lkQiSU70.png)

We'll need to move the `map.geojson` which we downloaded into our Docker container. Let's use `fio` to doublecheck that the `crs` for both the geojson and our image are identical.

```
fio info clip.geojson | jq '.'
```

We're going to need to reproject our geojson to `EPSG: 3857`.

```
fio cat clip.geojson --dst_crs "EPSG: 3857" | fio collect > clip-3857.geojson
```

Lovely, now we go ahead clip our image.

```
rio clip 432.TIF 432-clipped.TIF --bounds=$(fio info clip-3857.geojson --bounds)
```

![](https://cldup.com/VujONa9Ngq.png)

Not bad, but we could make this a little more beautiful using `rio color`

```
rio color clipped.TIF pretty.TIF sigmoidal RGB 5 0.5
```

![](https://cldup.com/AVOumX2wci.png)

These edits are pretty tame, but feel free to go crazy! Check out the [documentation](https://github.com/mapbox/rio-color#command-line-interface) for some ideas.


Matching colors
---------------

We can use the [rio-hist](https://github.com/mapbox/rio-hist) package to match colors from one set of imagery to another.

Let's download and process an additional Landsat scene which we can match to. We'll essentially need to repeat our previous step, but with a new path & row.

```
landsat download LC80070152016160LGN00 -d . -b2,3,4
landsat process /data/LC80070152016160LGN00 --bands 432
fio cat clip.geojson --dst_crs "EPSG: 3857" | fio collect > clip-3857.geojson
rio clip 432.TIF 432-clipped.TIF --bounds=$(fio info clip-3857.geojson --bounds)
```

![](https://cldup.com/Dp-_eSCCKM.png)

Let's match the color of our image from Bangalore to our new image.

```
rio hist -c LCH -b 1,2 432-clipped.TIF ../LC81440512016096LGN00/pretty.TIF  432-clipped-matched.TIF
```

![](https://cldup.com/l9ZrC9WksV.png)


Composite your image with our basemap
-------------------------------------

The last thing for us to do is to upload our results to Mapbox :)

Doing so will require that:
- you have a Mapbox account
- you have an AccessToken
- you've installed the [mapbox-cli-py](https://github.com/mapbox/mapbox-cli-py)

If you have all those things, you can:

```
mapbox upload LC80070152016160LGN00/432-clipped-matched.TIF jacques.blr-presentation
```

![](https://cldup.com/J6uyayyCic.png)
