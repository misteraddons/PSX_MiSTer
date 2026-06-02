local cue = os.getenv('PSX_CUE')
local outDir = os.getenv('PSX_OUT')
local maxBytes = tonumber(os.getenv('PSX_MAX_BYTES') or tostring(8 * 1024 * 1024))

if cue == nil or cue == '' then error('PSX_CUE is required') end
if outDir == nil or outDir == '' then error('PSX_OUT is required') end

local function cleanName(name)
    local s = name:gsub('[\\/:%*%?"<>|;]', '_')
    s = s:gsub('%s+', '_')
    if #s > 140 then s = s:sub(1, 140) end
    return s
end

local function joinPath(dir, name)
    return dir .. '/' .. name
end

local iso = PCSX.openIso(cue)
if iso:failed() then error('failed to open ISO: ' .. cue) end

local reader = iso:createReader()
local manifest = Support.File.open(joinPath(outDir, 'manifest.tsv'), 'TRUNCATE')
manifest:write('index\tpath\tsize\tlba\textracted\n')

local index = 0
local extracted = 0

local function walk(dir)
    local entries = reader:listDir(dir)
    for _, entry in ipairs(entries) do
        local child = dir
        if child ~= '' then child = child .. '/' end
        child = child .. entry.name

        if entry.isDir then
            local childNoVersion = child:gsub(';%d+$', '')
            walk(childNoVersion)
        else
            index = index + 1
            local extractedName = ''
            if entry.size <= maxBytes then
                extractedName = string.format('%04d_%s.bin', index, cleanName(child))
                local input = reader:open(child)
                if not input:failed() then
                    local output = Support.File.open(joinPath(outDir, extractedName), 'TRUNCATE')
                    local remaining = entry.size
                    while remaining > 0 do
                        local chunkSize = remaining
                        if chunkSize > 1048576 then chunkSize = 1048576 end
                        local buf = input:read(chunkSize)
                        if #buf == 0 then break end
                        output:write(buf)
                        remaining = remaining - #buf
                    end
                    output:close()
                    extracted = extracted + 1
                else
                    extractedName = ''
                end
            end
            manifest:write(string.format('%d\t%s\t%d\t%d\t%s\n', index, child, entry.size, entry.lba, extractedName))
        end
    end
end

walk('')
manifest:write(string.format('# extracted\t%d\n', extracted))
manifest:close()
PCSX.quit(0)
