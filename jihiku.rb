read in file

make list of words, delete duplicates
if null go to reading

Word, word[reading], meaning(english), example sentance, example sentace[reading]


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

wordlist = []

File.readlines('input.txt').each do |line| {
	
	line.sub!(' ]', '#$#')
	line.sub!(']: ', '#$#')
	list = line.split("#$#")
	
	if (list.length != 3) 
		puts "List length is not 3"
		puts list
	end
	
	word = list[0]

	if word == "null"
		word = list[1]
		list[0] = list[1]
	end
		

	wordlist.push(list)

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
