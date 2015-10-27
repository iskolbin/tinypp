local function preprocess( file, callback )
	local lines = type( file ) == 'string' and io.open( file, 'r' ) or file
	local format = string.format
	local chunk, n = {'local __innerchunk,__m = {},0\n'}, 1
	for line in lines:lines() do
		if string.find( line, '^#' ) then
			n = n + 1
			chunk[n] = string.sub( line, 2 )  .. "\n"
		else
			local last = 1
			for text, expr, index in string.gmatch( line, '(.-)$(%b())()' ) do 
				last = index
				if text ~= '' then
					n = n + 1
					chunk[n] = format('__m = __m+1\n__innerchunk[__m] = %q\n', text )
				end
				n = n + 1
				chunk[n] = format('__m = __m+1\n__innerchunk[__m] = %s\n', expr )
			end
			n = n + 1
			chunk[n] = ('__m = __m+1\n__innerchunk[__m] = ' .. format( '%q\n', string.sub( line, last ) .. '\n' ))
		end
	end

	n = n + 1
	chunk[n] = 'local __code = table.concat( __innerchunk )\n'

	if callback then
		n = n + 1
		chunk[n] = callback .. '( __code )\n'
	else
		n = n + 1
		chunk[n] = ('return assert(loadstring( __code ))()\n' )
	end

	if type( file ) == 'string' then
		io.close( lines )
	end

	return assert( loadstring( table.concat( chunk )))()
end

return preprocess
