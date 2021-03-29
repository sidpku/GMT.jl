@testset "GDAL" begin

#=
Gdal.GDALAllRegister()

driver = Gdal.GDALGetDriverByName("GTiff")
srs = Gdal.OSRNewSpatialReference(C_NULL)
Gdal.OSRImportFromEPSG(srs, 4326) 			# fails if GDAL_DATA is not set correctly
Gdal.GDALDestroyDriverManager()
=#

	version = Gdal.GDALVersionInfo("--version")
	n_gdal_driver = Gdal.GDALGetDriverCount()
	n_ogr_driver = Gdal.OGRGetDriverCount()
	@info """$version
	$n_gdal_driver GDAL drivers found
	$n_ogr_driver OGR drivers found
	"""

	dataset = creategd("", driver = getdriver("MEM"), width=241, height=181, nbands=1, dtype=Float64)
	crs = toWKT(importPROJ4("+proj=latlong"));
	crs = toWKT(importPROJ4("+proj=latlong"), true);
	writegd!(dataset, rand(181,241), 1)
	setproj!(dataset, crs)
	setgeotransform!(dataset, [-4.016666666666667, 0.03333333333333333, 0.0, -3.01666666666, 0.0, 0.03333333333333333])
	Gdal.listcapability(dataset)

	show(dataset)
	#G = gd2gmt(dataset);

	#readgd(dataset);		# Ambiguo
	band = getband(dataset);
	readgd(band);
	getproj(dataset)
	band = getband(dataset)
	Gdal.width(dataset)
	Gdal.width(band)
	Gdal.height(dataset)
	Gdal.height(band)
	Gdal.nlayer(dataset)
	Gdal.nraster(dataset)
	Gdal.filelist(dataset)
	Gdal.accessflag(band)
	Gdal.indexof(band)
	Gdal.pixeltype(band)
	Gdal.getcolorinterp(band)
	Gdal.getgeotransform(dataset)

	getdriver(dataset)
	getdriver(5)

	toPROJ4(importEPSG(4326))
	importWKT(crs)

	Gdal.shortname(getdriver("GTiff"));
	Gdal.longname(getdriver("GTiff"));
	Gdal.driveroptions("MEM");

	Gdal.GDALError();
	Gdal.CPLGetLastErrorNo();
	Gdal.CPLGetLastErrorMsg();
	Gdal.GDALGetColorInterpretationName(1);
	Gdal.GDALGetPaletteInterpretationName(1);
	Gdal.OCTDestroyCoordinateTransformation(C_NULL);

	gdalinfo("utmsmall.tif");
	ds_small = readgd("utmsmall.tif");
	Gdal.getlayer(ds_small, 1);
	gdalinfo(ds_small, [""]);
	gdaldem(ds_small, "hillshade", ["-q"]);
	gdaltranslate(ds_small, [""]);
	gdaltranslate("utmsmall.tif", R="442000/445000/3747000/3750000");

	gdalwarp(ds_small, [""]);
	ds_warped = gdalwarp("utmsmall.tif", ["-of","MEM","-t_srs","EPSG:4326"], gdataset=true)
	@test Gdal.width(ds_warped) == 109
	@test Gdal.height(ds_warped) == 91

	ds_point = readgd("point.geojson");
	ds_grid = gdalgrid(ds_point, ["-of","MEM","-outsize","3", "10","-txe","100","100.3","-tye","0","0.1"]);
	@test getgeotransform(ds_grid) ≈ [100.0,0.1,0.0,0.0,0.0,0.01]
	show(ds_point)
	Gdal.getlayer(ds_point, 0)
	#readgd(ds_grid)

	ds_csv = gdalvectortranslate(ds_point, ["-f","CSV","-lco", "GEOMETRY=AS_XY"], dest = "point.csv");
	#=
	@test replace(read("point.csv", String), "\r" => "") == """
	X,Y,FID,pointname
	100,0,2,point-a
	100.2785,0.0893,3,point-b
	100,0,0,a
	100.2785,0.0893,3,b
	"""
	=#

	Gdal.createmultipoint([(1251243.7361610543, 598078.7958668759), (1250318.7031934808, 606404.0925750365)]);

	@test GMT.R_inc_to_gd([0.01], " -R-11/-1/33/45")[1] == "-txe";

	dataset = Gdal.create(Gdal.getdriver("MEMORY"))
	layer = Gdal.createlayer(name = "point_out", dataset = dataset, geom = Gdal.wkbPoint)
	Gdal.addfielddefn!(layer, "Name", Gdal.OFTString, nwidth = 32)
	featuredefn = Gdal.layerdefn(layer)
	@test Gdal.getname(featuredefn) == "point_out"
	@test Gdal.nfeature(layer) == 0
	Gdal.createfeature(layer) do feature
		Gdal.setfield!(feature, Gdal.findfieldindex(feature, "Name"), "myname")
		Gdal.setgeom!(feature, Gdal.createpoint(100.123, 0.123))
	end
	@test Gdal.nfeature(layer) == 1

	ds_src = Gdal.read("utmsmall.tif")
	Gdal.write(ds_src, "/vsimem/utmsmall.tif")
	ds_copy = Gdal.read("/vsimem/utmsmall.tif")
	#@test Gdal.read(ds_src) == Gdal.read(ds_copy)
	Gdal.metadata(ds_src)
	Gdal.GDALGetDescription(ds_src.ptr)

	line = Gdal.createlinestring()
	Gdal.addpoint!(line, 1116651.439379124,  637392.6969887456)
	Gdal.OGR_G_SetPoints(line.ptr, 3, [1.,2,3], sizeof(Float64), [4.,5,6], sizeof(Float64), [7.,8,9], sizeof(Float64))
	xx = Gdal.getpoint(line, 1)
	@test xx == (2.0, 5.0, 8.0)

	G = GMT.peaks()
	ds = gmt2gd(G)
	G  = gd2gmt(ds)
	G = gd2gmt("utmsmall.tif");
	ds = gmt2gd(G)
	gdalinfo(ds);

	I = grdcut("utmsmall.tif", R="442000/445000/3747000/3750000", img=1);
	grdcut("utmsmall.tif", R="442000/445000/3747000/3750000", img=1, save="lixo.tif");
	grdcut("utmsmall.tif", R="442000/445000/3747000/3750000", img=1, save="lixo.tif");

	I = Gdal.dither("rgbsmall.tif");

	Gdal.GDALGetDataTypeByName("GTiff");
	Gdal.IFieldDefnView(C_NULL);
	Gdal.IGeomFieldDefnView(C_NULL);
	Gdal.GeomFieldDefn(C_NULL);
	Gdal.RasterBand(C_NULL);
	Gdal.destroy(Gdal.Driver(C_NULL));
	Gdal.destroy(Gdal.Feature(C_NULL));
	Gdal.destroy(Gdal.CoordTransform(C_NULL));
	Gdal.destroy(Gdal.FeatureDefn(C_NULL));
	Gdal.destroy(Gdal.IFieldDefnView(C_NULL));
	Gdal.destroy(Gdal.IGeomFieldDefnView(C_NULL));

	ds = gmt2gd(mat2ds([-8. 37.0; -8.1 37.5; -8.5 38.0]))
	Gdal.getx(Gdal.getgeom(Gdal.unsafe_getfeature(Gdal.getlayer(ds, 0),0)),1)
	Gdal.gety(Gdal.getgeom(Gdal.unsafe_getfeature(Gdal.getlayer(ds, 0),0)),1)
	Gdal.getz(Gdal.getgeom(Gdal.unsafe_getfeature(Gdal.getlayer(ds, 0),0)),1)
	Gdal.buffer(Gdal.getgeom(Gdal.unsafe_getfeature(Gdal.getlayer(ds, 0),0)), 0.2)

	#Gdal.identifydriver("lixo.gmt")
	D = mat2ds([-8. 37.0; -8.1 37.5; -8.5 38.0], proj="+proj=longlat");
	ds = gmt2gd(D)
	ds = gmt2gd(D, geometry="Polygon")
	ogr2ogr(D, dest="lixo.gmt")
	gmt2gd(D, save="lixo.gmt")
	ds = gmt2gd(D)
	ds2=ogr2ogr(ds, ["-t_srs", "+proj=utm +zone=29", "-overwrite"])
	gd2gmt(ds2)
end