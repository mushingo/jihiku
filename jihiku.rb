#encoding: UTF-8
require "nokogiri"
require "net/http"
require "uri"
	
#Word, word[reading], meaning(Japanese), example sentance, example sentace[reading]



def openPage(url)
	url = URI.parse(URI.encode(url))
	request = Net::HTTP::Get.new(url.path)


	request['User-Agent'] = "Firefox"

	
	response = Net::HTTP.start(url.host, url.port,:use_ssl => url.scheme == 'https') do |http|
		http.request(request)
	end

	if response.code == "301"
		new_url = response.header['location']
		new_url = "https://dictionary.goo.ne.jp" + new_url
		return openPage(new_url)
	end
	return response.body
end



def openResult(page, word)

	entry = page.css(".list-search-a li:first-child a").first

	
	if entry == nil
		return nil
	end
		
	entry = entry['href']

	url =  "https://dictionary.goo.ne.jp" + entry
	response = openPage(url)
	return Nokogiri::HTML(response)




end

def getSentence(definition)
	
	parts = definition.gsub("」", "").split("「")
	return parts.drop(1)
	
end

def makeSentences(sentences, word, reading)
	sentences.each do |sentence|
		if sentence.include?"―・"
			ending = reading.split("・")[1].split("〔")[0]
			start = word[0, word.rindex(ending)]
			sentence.gsub!("―・", start)
		
		else
		sentence.gsub!("―", word)
		end
			   
	end
	return sentences
end



wordlist = {}


File.readlines('input2.txt').each do |line| 
	wordlist[line.strip().force_encoding("UTF-8")] = [nil, nil, nil, nil, nil]
end

i = 1

missing = []
wordlist2 = {}

wordlist.each do |item,key| 
	word = item
	i = i + 1
	url_front = "https://dictionary.goo.ne.jp/srch/jn/".force_encoding("UTF-8") 
	url_end = "/m0u/".force_encoding("UTF-8")
	url = url_front + word + url_end

	response = openPage(url)

	page = Nokogiri::HTML(response)

	title = page.css('title').text

	if page.css('title').text.include? "検索結果"
		page = openResult(page, word)
		if page == nil 
			missing.push(word)
			next
		end
	end
	puts page.css("title").text

	if page.css('title').text.include? "英語で訳す"
		missing.push(word)
		next
	end
			     
	if page.css('title').text.include? "404"
		missing.push(word)
		next
	end
		
	#Split up into cases jap dict, yojijukugo, eigo etc
	#
	definitions_list = page.css(".contents_area .contents .text")
	reading = page.css(".section .basic_title h1").text
	reading = reading.gsub("の意味", "")

	reading = reading.gsub("】","")
	reading_kanji = reading.split("【")
	kanji = ""
	if reading_kanji.size > 1
		kanji = reading_kanji[1]#if more than 1?
	end
	reading = reading_kanji[0]
	puts word, reading

	reading = reading.gsub("〕", "")
	reading_alt = reading.split("〔")
	alternate_reading = ""
	if reading_alt.size > 1 
		alternate_reading = reading_alt[1]#if more than 1?
	end
	reading = reading_alt[0]


	definition = ""
	hinshi = ""

	entries = []

	definitions_list.each do |entry|
		hinshi = entry.css(".hinshi").text
		definition =  entry.text.gsub(hinshi, "")
		note_def = definition.split("》")
		note = ""
		if note_def.size > 1
			size = note_def.size - 1
			n = 0
			note = ""
			while n < size
			       note = note + note_def[n] + "》 "
			 n = n + 1
			end	 


			definition = note_def[size]
		end
		sentences = getSentence(definition)
		sentences.each do |sentence|
			definition = definition.gsub(sentence, "")
			definition = definition.gsub("「」","")
		end

		sentences = makeSentences(sentences,word, reading)

		entries.push([reading, alternate_reading, kanji, hinshi, note, definition,sentences])
	end	


	wordlist2[word] = entries

	if i > 50
		wordlist2.each do |key, value|
			puts "word:" + key
			value.each do |definition|
				puts "reading: " + definition[0].to_s
				puts "alternate reading: " + definition[1].to_s
				puts "kanji: " + definition[2].to_s
				puts "hinshi: " + definition[3].to_s
				puts "note: " + definition[4].to_s
				puts "definition: " + definition[5].to_s
				puts "sentences: " + definition[6].to_s

				puts
			end
		end
		puts missing
		exit
	end

	next

	exit
	i = 1
	while true
		#page.css("h2")
		xpath = "(//P[@class='text'])[" + i.to_s + "]"
		xpath_reibun = "//DIV[@class='text']"
		entry = page.xpath(xpath)
		puts entry
		if entry[0...2] == "･･･"
			entry = page.xpath(xpath_reibun)
		end
		puts 
		entry = entry.tr("」","").split("「")

		definition = entry[0]
		sentences = entry.drop(1)
		sentance = sentences[0] #pickBestSentance(sentences, null)
#		sentance_alt = #pickBestSentance(sentences, sentance)
		
		i += 1
	end
end

