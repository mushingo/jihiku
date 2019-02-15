

	
Word, word[reading], meaning(Japanese), example sentance, example sentace[reading]


def getWebsiteResponse(url) 
	attempts = 0

	while attempts < 10 do 
		attempts += 1

		begin 
			response = RestClient.get(url) {|res, request, result, &block|
				case res.code
				when 200
					res
				else	
					File.open("error.log", "a") do |f|
						f.write(res.code.to_json)
					end
					res = 0				
				end
			}
	
		rescue RestClient::ExceptionWithResponse => err
			File.open("error.log", "a") do |f|
				f.write(err.to_json)
			end
			response = 0
		end

		if response == 0
			sleep(attempts * 3)
			print "attempting again\n"

		else
			break
		end
	end

	return response	

end

def openResult(page, word)
	entries = page.xpath("//a")  #("//dt[@class='title search-ttl-a']")
	urlSnippit = "/" + word + "/"
	url = ""
	entries.each do |entry| {
		html = entry["href"]
		if html.include? urlSnippit
			url = html
		end
		
	}
	
	response = getWebsiteResponse(html)
	return Nokogiri::HTML(response)



end

wordlist = {}

wordlist = {}

for line in input 
	
end
	
File.readlines('input.txt').each do |line| {	
	wordlist[line.strip()] = [null, null, null, null, null]
}

wordlist = wordlist.uniq

wordlist.each do |item| {
	word = item[0]

	url = "https://dictionary.goo.ne.jp/srch/jn/" + word + "/m0u/"

	response = getWebsiteResponse(url)

	page = Nokogiri::HTML(response)

	title = page.css('title').text

	if title.include? "検索結果"
		page = openResult(page)
	end
	

























}
