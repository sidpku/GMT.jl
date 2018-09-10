"""
	grdlandmask(cmd0::String="", arg1=[], kwargs...)

Reads the selected shoreline database and uses that information to decide which nodes in the
specified grid are over land or over water.

Full option list at [`grdlandmask`](http://gmt.soest.hawaii.edu/doc/latest/grdlandmask.html)

Parameters
----------

- $(GMT.opt_R)
- **I** : **inc** : -- Str or Number --

    *x_inc* [and optionally *y_inc*] is the grid spacing.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/grdlandmask.html#i)
- **A** : **area** : -- Str or Number --

    Features with an area smaller than min_area in km^2 or of
    hierarchical level that is lower than min_level or higher than
    max_level will not be plotted.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/grdlandmask.html#a)
- **D** : **res** : **resolution** : -- Str --

    Selects the resolution of the data set to use ((f)ull, (h)igh, (i)ntermediate, (l)ow, and (c)rude).
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/grdlandmask.html#d)
- **E** : **bordervalues** : -- Str or List --    Flags = cborder/lborder/iborder/pborder or bordervalue

    Nodes that fall exactly on a polygon boundary should be considered to be outside the polygon
    [Default considers them to be inside].
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/grdlandmask.html#e)
- **G** : **outgrid** : -- Str --

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdlandmask(....) form.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/grdlandmask.html#g)
- **N** : **mask_geog** : -- Str or List --    Flags = wet/dry or ocean/land/lake/island/pond

    Sets the values that will be assigned to nodes. Values can be any number, including the textstring NaN
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/grdlandmask.html#n)
- $(GMT.opt_V)
- $(GMT.opt_r)
- $(GMT.opt_x)
"""
function grdlandmask(cmd0::String=""; kwargs...)

	length(kwargs) == 0 && return monolitic("grdlandmask", cmd0, [])	# Speedy mode

	d = KW(kwargs)

	cmd, = parse_R("", d)
	cmd = parse_V_params(cmd, d)
	cmd, = parse_r(cmd, d)
	cmd, = parse_x(cmd, d)

	cmd = add_opt(cmd, 'A', d, [:A :area])
	cmd = add_opt(cmd, 'D', d, [:D :res :resolution])
	cmd = add_opt(cmd, 'E', d, [:E :bordervalues])
    cmd = add_opt(cmd, 'I', d, [:I :inc])
	cmd = add_opt(cmd, 'G', d, [:G :outgrid])
	cmd = add_opt(cmd, 'N', d, [:N :mask_geog])

	return common_grd(d, cmd, 1, 1, "grdlandmask", [])		# Finish build cmd and run it
end