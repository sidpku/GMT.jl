# Parse the common options that all GMT modules share, plus some others functions of also common usage

const KW = Dict{Symbol,Any}

function parse_R(cmd::String, d::Dict, O=false)
	# Build the option -R string. Make it simply -R if overlay mode (-O) and no new -R is fished here
	opt_R = ""
	for sym in [:R :region :limits]
		if (haskey(d, sym))
			opt_R = build_opt_R(d[sym])
			break
		end
	end
	if (O && isempty(opt_R))  opt_R = " -R"  end
	cmd = cmd * opt_R
	return cmd, opt_R
end

function build_opt_R(Val)
	if (isa(Val, String))
		return " -R" * Val
	elseif (isa(Val, Array) && length(Val) == 4)
		return @sprintf(" -R%.14g/%.14g/%.14g/%.14g", Val[1], Val[2], Val[3], Val[4])
	end
	return ""
end

# ---------------------------------------------------------------------------------------------------
function parse_JZ(cmd::String, d::Dict)
	for sym in [:JZ :Jz]
		if (haskey(d, sym))
			if (sym == :JZ)
				cmd = cmd * " -JZ" * arg2str(d[sym])
			else
				cmd = cmd * " -Jz" * arg2str(d[sym])
			end
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_J(cmd::String, d::Dict, O=false)
	# Build the option -J string. Make it simply -J if overlay mode (-O) and no new -J is fished here
	# Default to 14c if no size is provided
	opt_J = ""
	for symb in [:J :proj :projection]
		if (haskey(d, symb))
			opt_J = build_opt_J(d[symb])
			break
		end
	end
	if (O && isempty(opt_J))  opt_J = " -J"  end

	if (!O && !isempty(opt_J))
		# If only the projection but no size, try to get it from the kwargs.
		if (haskey(d, :figsize))
			if (isa(d[:figsize], Number))
				s = @sprintf("%.8g", d[:figsize])
			elseif (isa(d[:figsize], Array) && length(d[:figsize]) == 2)
				s = @sprintf("%.10g/%.10g", d[:figsize][1], d[:figsize][2])
			elseif (isa(d[:figsize], String))
				s = d[:figsize]
			else
				error("What the hell is this figwidth argument?")
			end
			if (haskey(d, :units))
				s = s * d[:units][1]
			end
			if (isdigit(opt_J[end]))  opt_J = opt_J * "/" * s
			else                      opt_J = opt_J * s
			end
		elseif (length(opt_J) == 4 || (length(opt_J) >= 5 && isalpha(opt_J[5])))	# No size provided
			opt_J = opt_J * "14c"			# If no size, default to 14 centimeters
		end
	end
	cmd = cmd * opt_J
	return cmd, opt_J
end

function build_opt_J(Val)
	if (isa(Val, String))
		return " -J" * Val
	elseif (isempty(Val))
		return " -J"
	end
	return ""
end

# ---------------------------------------------------------------------------------------------------
function parse_B(cmd::String, d::Dict, opt_B::String="")
	for sym in [:B :frame :axes]
		if (haskey(d, sym) && isa(d[sym], String))
			opt_B = d[sym]
			break
		end
	end

	tok = Vector{String}(10)
	k = 1
	r = opt_B
	while (!isempty(r))
		tok[k],r = GMT.strtok(r)
		if (ismatch(r"[WESNwesntlbu+g+o]", tok[k]) && searchindex(tok[k], "+t") == 0)		# If title here, forget about :title
			if (haskey(d, :title) && isa(d[:title], String))
				tok[k] = tok[k] * "+t\"" * d[:title] * "\""
			end
		elseif (ismatch(r"[afgpsxyz+S+u]", tok[k]) && !ismatch(r"[+l+L]", tok[k]))		# If label here, forget about :x|y_label
			if (haskey(d, :x_label) && isa(d[:x_label], String))  tok[k] = tok[k] * " -Bx+l\"" * d[:x_label] * "\""  end
			if (haskey(d, :y_label) && isa(d[:y_label], String))  tok[k] = tok[k] * " -By+l\"" * d[:y_label] * "\""  end
		end
		if (searchindex(tok[k], "-B") == 0)  tok[k] = " -B" * tok[k]
		else                                 tok[k] = " " * tok[k]
		end
		k = k + 1
	end
	# Rebuild the B option string
	opt_B = ""
	for n = 1:k-1
		opt_B = opt_B * tok[n]
	end

	if (!isempty(opt_B))  cmd = cmd * opt_B  end
	return cmd, opt_B
end

# ---------------------------------------------------------------------------------------------------
function parse_X(cmd::String, d::Dict)
	# Parse the global -X option. Return CMD same as input if no -X option in args
	if (haskey(d, :X))
		cmd = cmd * " -X" * arg2str(d[:X])
	elseif (haskey(d, :x_offset))
		cmd = cmd * " -X" * arg2str(d[:x_offset])
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_Y(cmd::String, d::Dict)
	# Parse the global -Y option. Return CMD same as input if no -Y option in args
	if (haskey(d, :Y))
		cmd = cmd * " -Y" * arg2str(d[:Y])
	elseif (haskey(d, :y_offset))
		cmd = cmd * " -Y" * arg2str(d[:y_offset])
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_U(cmd::String, d::Dict)
	# Parse the global -U option. Return CMD same as input if no -U option in args
	if (haskey(d, :U))
		cmd = cmd * " -U" * arg2str(d[:U])
	elseif (haskey(d, :stamp))
		cmd = cmd * " -U" * arg2str(d[:stamp])
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_V(cmd::String, d::Dict)
	# Parse the global -V option. Return CMD same as input if no -V option in args
	for symb in [:V :verbose]
		if (haskey(d, symb))
			if (isa(d[symb], Bool) && d[symb]) cmd = cmd * " -V"
			else                               cmd = cmd * " -V" * arg2str(d[symb])
			end
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_a(cmd::String, d::Dict)
	# Parse the global -a option. Return CMD same as input if no -a option in args
	for symb in [:a :aspatial]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -a" * d[symb]
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_bi(cmd::String, d::Dict)
	# Parse the global -bi option. Return CMD same as input if no -bi option in args
	opt_bi = ""
	for symb in [:bi :binary_in]
		if (haskey(d, symb))
			opt_bi = " -bi" * arg2str(d[symb])
			cmd = cmd * opt_bi
			break
		end
	end
	return cmd, opt_bi
end

# ---------------------------------------------------------------------------------------------------
function parse_bo(cmd::String, d::Dict)
	# Parse the global -bo option. Return CMD same as input if no -bo option in args
	for symb in [:bo :binary_out]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -bo" * d[symb]
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_di(cmd::String, d::Dict)
	# Parse the global -di option. Return CMD same as input if no -di option in args
	opt_di = ""
	for symb in [:di :nodata_in]
		if (haskey(d, symb) && isa(d[symb], Number))
			opt_di = " -di" * arg2str(d[symb])
			cmd = cmd * opt_di
			break
		end
	end
	return cmd, opt_di
end

# ---------------------------------------------------------------------------------------------------
function parse_e(cmd::String, d::Dict)
	# Parse the global -e option. Return CMD same as input if no -e option in args
	for symb in [:e :pattern]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -e" * d[symb]
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_f(cmd::String, d::Dict)
	# Parse the global -f option. Return CMD same as input if no -f option in args
	for symb in [:f :colinfo]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -f" * d[symb]
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_g(cmd::String, d::Dict)
	# Parse the global -g option. Return CMD same as input if no -g option in args
	for symb in [:g :gaps]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -g" * d[symb]
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_h(cmd::String, d::Dict)
	# Parse the global -h option. Return CMD same as input if no -h option in args
	for symb in [:h :headers]
		if (haskey(d, symb))
			cmd = cmd * " -h" * arg2str(d[symb])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_i(cmd::String, d::Dict)
	# Parse the global -i option. Return CMD same as input if no -i option in args
	opt_i = ""
	for symb in [:i :input_col]
		if (haskey(d, symb) && isa(d[symb], String))
			opt_i = " -i" * d[symb]
			cmd = cmd * opt_i
			break
		end
	end
	return cmd, opt_i
end

# ---------------------------------------------------------------------------------------------------
function parse_n(cmd::String, d::Dict)
	# Parse the global -n option. Return CMD same as input if no -n option in args
	for symb in [:n :interp :interp_method]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -n" * d[symb]
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_swappxy(cmd::String, d::Dict)
	# Parse the global -: option. Return CMD same as input if no -: option in args
	# But because we acn't have a variable called ':' we use only the 'swappxy' alias
	for symb in [:swappxy]
		if (haskey(d, symb))
			cmd = cmd * " -:" * arg2str(d[symb])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_p(cmd::String, d::Dict)
	# Parse the global -p option. Return CMD same as input if no -p option in args
	for symb in [:p :view :perspective]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -p" * d[symb]
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_r(cmd::String, d::Dict)
	# Parse the global -r option. Return CMD same as input if no -r option in args
	for symb in [:r :reg :registration]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -r" * d[symb]
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_t(cmd::String, d::Dict)
	# Parse the global -t option. Return CMD same as input if no -t option in args
	for symb in [:t :alpha :transparency]
		if (haskey(d, symb) && isa(d[symb], Number))
			cmd = @sprintf("%s -t%.6g", cmd, d[symb])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function opt_pen(d::Dict, opt::Char, symbs)
	# Create an option string of the type -Wpen
	out = ""
	pen = build_pen(d)						# Either a full pen string or empty ("")
	if (!isempty(pen))
		out = " -" * opt * pen
	else
		for sym in symbs
			if (haskey(d, sym))
				if (isa(d[sym], String))
					out = " -" * opt * arg2str(d[sym])
				elseif (isa(d[sym], Tuple))	# Like this it can hold the pen, not extended atts
					out = " -" * opt * parse_pen(d[sym])
				else
					error("Nonsense in " * opt * " option")
				end
				break
			end
		end
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
function parse_pen(pen::Tuple)
	# Convert a empty to 3 args tuple containing (width[c|i|p]], [color], [style[c|i|p|])
	len = length(pen)
	if (len == 0) return "0.25p" end 	# just the default pen
	s = arg2str(pen[1])					# First arg is differene because there is no leading ','
	for k = 2:len
		if (isa(pen[k], Number))
			s = @sprintf("%s,%.8g", s, pen[k])
		else
			s = @sprintf("%s,%s", s, pen[k])
		end
	end
	return s
end

# ---------------------------------------------------------------------------------------------------
function parse_pen_width(d::Dict)
	# Search for a "lw" or "linewidth" specification
	pw = ""
	for sym in [:lw :linewidth :LineWidth]
		if (haskey(d, sym))
			if (isa(d[sym], Number))      pw = @sprintf("%.6g", d[sym])
			elseif (isa(d[sym], String))  pw = d[sym]
			else error("Nonsense in line width argument")
			end
			break
		end
	end
	return pw
end

# ---------------------------------------------------------------------------------------------------
function parse_pen_color(d::Dict)
	# Search for a "lc" or "linecolor" specification
	pc = ""
	for sym in [:lc :linecolor :LineColor]
		if (haskey(d, sym))
			if (isa(d[sym], String))      pc = d[sym]
			elseif (isa(d[sym], Number))  pc = @sprintf("%d", d[sym])
			else error("Nonsense in line color argument")
			end
			break
		end
	end
	return pc
end

# ---------------------------------------------------------------------------------------------------
function parse_pen_style(d::Dict)
	# Search for a "ls" or "linestyle" specification
	ps = ""
	for sym in [:ls :linestyle :LineStyle]
		if (haskey(d, sym))
			if (isa(d[sym], String))      ps = d[sym]
			elseif (isa(d[sym], Number))  ps = @sprintf("%d", d[sym])
			else error("Nonsense in line color argument")
			end
			break
		end
	end
	return ps
end

# ---------------------------------------------------------------------------------------------------
function build_pen(d::Dict)
	# Search for lw, lc, ls in d and create a pen string in case they exist
	# If no pen specs found, return the empty string ""
	lw = parse_pen_width(d)
	lc = parse_pen_color(d)
	ls = parse_pen_style(d)
	if (!isempty(lw) || !isempty(lc) || !isempty(ls))
		return lw * "," * lc * "," * ls
	else
		return ""
	end
end

# ---------------------------------------------------------------------------------------------------
function parse_arg_and_pen(arg::Tuple)
	# Parse an ARG of the type (arg, (pen)) and return a string. These may be used in pscoast -I & -N
	if (isa(arg[1], String))      s = arg[1]
	elseif (isa(arg[1], Number))  s = @sprintf("%d", arg[1])
	else	error("Nonsense first argument")
	end
	if (length(arg) > 1 && isa(arg[2], Tuple))
		s = s * "/" * parse_pen(arg[2])
	end
	return s
end

# ---------------------------------------------------------------------------------------------------
function arg2str(arg)
	# Convert an empty, a numeric or string ARG into a string ... if it's not one to start with
	# ARG can also be a Bool, in which case the TRUE value is converted to "" (empty string)
	if (isa(arg, String))
		out = arg
	elseif (isempty(arg) || (isa(arg, Bool) && arg))
		out = ""
	elseif (isa(arg, Number))			# Have to do it after the Bool test above because Bool is a Number too
		out = @sprintf("%.6g", arg)
	else
		error("Argument 'arg' can only be a String or a Number")
	end
end

# ---------------------------------------------------------------------------------------------------
function finish_PS(d::Dict, cmd0::String, cmd::String, output::String, K::Bool, O::Bool)
	# Finish a PS creating command. All PS creating modules should use this.
	if (!haskey(d, :P) && !haskey(d, :portrait))
		cmd = cmd * " -P"
	end

	if (!isempty(cmd0))
		cmd = cmd * " " * cmd0		# Append any other eventual args not send in via kwargs
	end
	
	# Cannot mix -O,-K and output redirect between positional and kwarg arguments
	if (isempty(search(cmd0, "-K")) && isempty(search(cmd0, "-O")) && isempty(search(cmd0, ">")))
		# So the -O -K dance is provided via kwargs
		if (K && !O)              opt = " -K"
		elseif (K && O)           opt = " -K -O"
		elseif (!K && O)          opt = " -O"
		else                      opt = ""
		end

		if (!isempty(output))
			if (K && !O)          cmd = cmd * opt * " > " * output
			elseif (!K && !O)     cmd = cmd * opt * " > " * output
			elseif (O)            cmd = cmd * opt * " >> " * output
			end
		else
			if (K && !O)          cmd = cmd * opt
			elseif (!K && !O)     cmd = cmd * opt
			elseif (O)            cmd = cmd * opt
			end
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function add_opt(cmd::String, opt, d::Dict, symbs)
	# Scan the D Dict for SYMBS keys and if found create the new option OPT and append it to CMD
	for sym in symbs
		if (haskey(d, sym))
			cmd = string(cmd, " -", opt, arg2str(d[sym]))
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function add_opt_s(cmd::String, opt, d::Dict, symbs)
	# Same as add_opt() but where we only accept string arguments
	for sym in symbs
		if (haskey(d, sym) && isa(d[sym], String))
			cmd = string(cmd, " -", opt, d[sym])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function fname_out(out::String)
	# Create an file name in the TMP dir when OUT holds only a known extension. The name is: GMTjl_tmp.ext
	opt_T = "";		EXT = ""
	if (length(out) <= 3)
		@static is_windows() ? template = tempdir() * "GMTjl_tmp.ps" : template = tempdir() * "/" * "GMTjl_tmp.ps" 
		ext = lowercase(out)
		if (ext == "ps")       out = template
		elseif (ext == "pdf")  opt_T = " -Tf";	out = template;		EXT = ext
		elseif (ext == "eps")  opt_T = " -Te";	out = template;		EXT = ext
		elseif (ext == "png")  opt_T = " -Tg";	out = template;		EXT = ext
		elseif (ext == "jpg")  opt_T = " -Tj";	out = template;		EXT = ext
		elseif (ext == "tif")  opt_T = " -Tt";	out = template;		EXT = ext
		end
	end
	return out, opt_T, EXT
end

# ---------------------------------------------------------------------------------------------------
function show_or_save(d::Dict, output::String, fname_ext::String, opt_T::String, K::Bool)
	# Display Fig in default viewer or save it to file after converting with psconvert
	if (haskey(d, :show))
		showfig(output, fname_ext, opt_T, K)
	elseif (haskey(d, :savefig))
		showfig(output, fname_ext, opt_T, K, d[:savefig])
	end	
end

# ---------------------------------------------------------------------------------------------------
function showfig(fname_ps::String, fname_ext::String, opt_T::String, K=false, fname="")
	# Take a PS file, convert it with psconvert (unless opt_T == "" meaning file is PS)
	# and display it in default system viewer
	if (!isempty(opt_T))
		if (K) gmt("psxy -T -R0/1/0/1 -JX1 -O >> " * fname_ps)  end			# Close the PS file first
		gmt("psconvert -A1p -Qg4 -Qt4 " * fname_ps * opt_T)
		out = fname_ps[1:end-2] * fname_ext
	else
		out = fname_ps
	end
	if (is_windows()) run(ignorestatus(`explorer $out`))
	elseif (is_apple()) run(`open $(out)`)
	elseif (is_linux()) run(`xdg-open $(out)`)
	end
end

# ---------------------------------------------------------------------------------------------------
function isempty_(arg)
	# F... F... it's a shame having to do this
	empty = false
	try
		empty = isempty(arg)
	end
	return empty
end

# ---------------------------------------------------------------------------------------------------
function put_in_slot(cmd::String, val, opt::Char, args)
	# Find the first non-empty slot in ARGS and assign it the Val of d[:symb]
	# Return also the index of that first non-empty slot in ARGS
	k = 1
	for arg in args					# Find the first empty slot
		if (isempty_(arg))
			cmd = string(cmd, " -", opt)
			break
		end
		k += 1
	end
	return cmd, k
end

# --------------------------------------------------------------------------------------------------
function peaks(N=49)
	x,y = meshgrid(linspace(-3,3,N))
	
	z =  3 * (1.-x).^2 .* exp.(-(x.^2) - (y+1).^2) - 10*(x./5 - x.^3 - y.^5) .* exp.(-x.^2 - y.^2)
	   - 1/3 * exp.(-(x+1).^2 - y.^2)
	return x,y,z
end	

meshgrid(v::AbstractVector) = meshgrid(v, v)
function meshgrid{T}(vx::AbstractVector{T}, vy::AbstractVector{T})
	m, n = length(vy), length(vx)
	vx = reshape(vx, 1, n)
	vy = reshape(vy, m, 1)
	(repmat(vx, m, 1), repmat(vy, 1, n))
end

function meshgrid{T}(vx::AbstractVector{T}, vy::AbstractVector{T}, vz::AbstractVector{T})
	m, n, o = length(vy), length(vx), length(vz)
	vx = reshape(vx, 1, n, 1)
	vy = reshape(vy, m, 1, 1)
	vz = reshape(vz, 1, 1, o)
	om = ones(Int, m)
	on = ones(Int, n)
	oo = ones(Int, o)
	(vx[om, :, oo], vy[:, on, oo], vz[om, on, :])
end