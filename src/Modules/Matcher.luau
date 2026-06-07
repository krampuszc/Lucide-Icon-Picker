-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT
--
-- Fuzzy + exact string matcher. Pass a list of strings as candidates,
-- then call :match(query) to get a ranked subset.

local M = {}

function M.new(candidates, search_case_insensitive, search_fuzzy)
	local m = {
		search_case_insensitive = search_case_insensitive,
		search_fuzzy = search_fuzzy,
	}
	setmetatable(m, { __index = M })
	m:_set_candidates(candidates)
	return m
end

local function match_score(line, matchers)
	local score = 0
	for _, matcher in ipairs(matchers) do
		local s = matcher(line)
		if not s then return nil end
		score = score + s
	end
	return score
end

function M:match(search)
	if not search or #search == 0 then return self.candidates end
	local cache = self.cache
	if self.search_case_insensitive then search = search:lower() end
	local matches = cache.matches[search] or {}
	if #matches > 0 then return matches end
	local lines = cache.lines[string.sub(search, 1, -2)] or self.lines
	local matchers = self:_matchers_for_search(search)

	local matching_lines = {}
	for _, line in ipairs(lines) do
		local score = match_score(line.text, matchers)
		if score then
			matches[#matches + 1] = { index = line.index, score = score }
			matching_lines[#matching_lines + 1] = line
		end
	end
	cache.lines[search] = matching_lines

	table.sort(matches, function(a, b) return a.score < b.score end)
	local out = {}
	for _, match in ipairs(matches) do
		out[#out + 1] = self.candidates[match.index]
	end
	self.cache.matches[search] = out
	return out
end

function M:_set_candidates(candidates)
	self.candidates = candidates
	self.cache = { lines = {}, matches = {} }
	local lines = {}
	local fuzzy_penalty = 0
	for i, candidate in ipairs(candidates) do
		local text = type(candidate) == "table" and table.concat(candidate, " ") or candidate
		if self.search_case_insensitive then text = text:lower() end
		lines[#lines + 1] = { text = text, index = i }
		fuzzy_penalty = math.max(fuzzy_penalty, #text)
	end
	self.lines = lines
	self.fuzzy_score_penalty = fuzzy_penalty
end

local pattern_escapes = {}
for c in string.gmatch("^$()%.[]*+-?", ".") do pattern_escapes[c] = "%" .. c end

local function fuzzy_pattern(search)
	local p = ""
	for i = 1, #search do
		local c = search:sub(i, i)
		p = p .. (pattern_escapes[c] or c) .. ".-"
	end
	return p
end

function M:_matchers_for_search(search_string)
	local fuzzy = self.search_fuzzy
	local penalty = self.fuzzy_score_penalty
	local groups = {}
	for part in search_string:gmatch("%S+") do groups[#groups + 1] = part end
	local matchers = {}
	for _, search in ipairs(groups) do
		local fp = fuzzy and fuzzy_pattern(search)
		matchers[#matchers + 1] = function(line)
			local s, e = line:find(search, 1, true)
			local score = s
			if not s and fuzzy then
				s, e = line:find(fp)
				if s then score = (e - s) + penalty end
			end
			if score then return score + #line end
		end
	end
	return matchers
end

return M
