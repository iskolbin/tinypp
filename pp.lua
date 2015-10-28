--	Input: 
--		file -- file opened in read mode or path
--		callback:
--			nil: file will be preprocessed and executed
--			{filepath}: file will be preprocessed and written to specified filepath
--			string: file will be preprocessed and result will be passed to string(for example "io.write" will print to console )
--	Output:
--		depends on specified callback. If no callback specified then returns execution result. For {filepath} no result. For string: depends on string, i.e., for example if you type "return" then you get preprocessed string.

local function preprocess( file, callback )
	local lines = type( file ) == 'string' and io.open( file, 'r' ) or file
	local chunk, n = {'local __innerchunk,__m = {},0\n'}, 1
	for line in lines:lines() do
		if line:find'^#' then
			n = n + 1
			chunk[n] = line:sub( 2 )  .. "\n"
		else
			local last = 1
			for text, expr, index in line:gmatch'(.-)$(%b())()' do 
				last = index
				if text ~= '' then
					n = n + 1
					chunk[n] = ('__m = __m+1\n__innerchunk[__m] = %q\n'):format( text )
				end
				n = n + 1
				chunk[n] = ('__m = __m+1\n__innerchunk[__m] = %s\n'):format( expr )
			end
			n = n + 1
			chunk[n] = '__m = __m+1\n__innerchunk[__m] = ' .. ('%q\n'):format( line:sub( last ) .. '\n' )
		end
	end

	n = n + 1
	chunk[n] = 'local __code = table.concat( __innerchunk )\n'
		
	n = n + 1
	if callback then
		if type( callback ) == 'table' then
			local path = callback[1]
			chunk[n] = ('local __outfile = assert(io.open(%q,"w+"))\n__outfile:write( __code )\nio.close(__outfile)\n'):format( path )
		else
			chunk[n] = callback .. '( __code )\n'
		end
	else
		chunk[n] = ('return assert(loadstring( __code ))()\n' )
	end

	if type( file ) == 'string' then
		io.close( lines )
	end

	return assert( loadstring( table.concat( chunk )))()
end

if ... ~= 'pp' then
	local infile, outfile = ...
	if not infile then
		print( 'Tiny Lua Preprocessor' )
		print( 'usage: pp <infile> <outfile>' )
		print( 'if no outfile specified then will use stdout' )
	else
		preprocess( infile, outfile and {outfile} or 'io.write' )
	end
end

return preprocess
