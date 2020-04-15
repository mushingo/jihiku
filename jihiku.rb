#encoding: UTF-8
require "nokogiri"
require "net/http"
require "uri"
	
#Word, word[reading], meaning(Japanese), example sentance, example sentace[reading]

CONTENTS = "contents-wrap"
SECTION = "section"
CONTENTS_HEADING_CSS = ".contents-wrap-b-in .basic_title h2"
SECTION_HEADING_CSS = 	".section .basic_title.nolink.jn h1"
CONTENTS_HEADING_SUB = "の解説"
SECTION_HEADING_SUB = "の意味"
CONTENTS_DEFINITION_CSS = ".contents-wrap-b-in .meaning_area"
SECTION_DEFINITION_CSS = ".section .contents_area"





def openPage(url)

	url = URI.parse(url)
	request = Net::HTTP::Get.new(url.path)

	request['User-Agent'] = "Firefox"

	puts url

	
	response = Net::HTTP.start(url.host, url.port,:use_ssl => url.scheme == 'https') do |http|
		http.request(request)
	end
	
	if response.code == "301"
		new_url = response.header['location']
		new_url = "https://dictionary.goo.ne.jp" + new_url
		return openPage(new_url)
	end

	if response.code != "200"
		puts response.code
		exit
	end
	
	return response.body
end



def selectMatchingEntries(page, word)

	search_results = page.css(".content_list a").map { |anchor| anchor["href"] }
	encoded_word = URI.encode("/" + word + "/")
	puts encoded_word
	found = false

	entries = []

	search_results.each do |result_url|
		if ["thsrs", "wpedia", "person", "srch"].any? { |skip| result_url.include? skip }
			next
		end
		if result_url.include?encoded_word
			puts result_url
			entries.push("https://dictionary.goo.ne.jp" + result_url)
			found = true
		end
	end

	if found == true
		return entries
	end

	#if not found select first entry

	result = page.css(".content_list li:first-child a").first

	
	if result == nil
		return []
	end
		
	return entries.push("https://dictionary.goo.ne.jp" + result['href'])


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


def processKokugo(page, expression)
#	description = page.xpath('/html/head/meta[@name="description"]/@content').to_s
#	puts description
#	puts
	definitions = Array.new
	if page.at_css(".contents-wrap-b-in")
		signal = CONTENTS
		heading_css = CONTENTS_HEADING_CSS
		heading_sub = CONTENTS_HEADING_SUB
		definition_css = CONTENTS_DEFINITION_CSS
	else
		heading_css = SECTION_HEADING_CSS
		signal = SECTION
		heading_sub = SECTION_HEADING_SUB
		definition_css = SECTION_DEFINITION_CSS
	end
	single_css = " .contents .text"
	multiple_css = " .contents .meaning"

#	puts signal
	heading = page.css(heading_css).text
	heading = heading.gsub(heading_sub, "").strip

#	puts puts "heading: " + heading

	if page.at_css(definition_css + multiple_css)

		items = page.css(definition_css + " .contents li")
		items.each do |item|
			definitions.push(item.css("p").text)
		end
	else
	
		
		definitions.push(page.css(definition_css + single_css).text)
	end

	

	hinshi = page.css(".hinshi").text

	definitions.each do |definition|

		

#		puts "last: " + definition[-1]

		definition =  definition.gsub(hinshi, "")

		sentence = ""

		if definition[-1].include? "」"
			definition, sentence = definition.split("「")
			sentence = sentence.gsub("」", "")
		end
	
		if heading.include? "【"
			reading, kanji = heading.split("【")
			kanji = kanji.gsub("】", "")
		else
			kanji = ""
			reading = ""
		end
	
#check its not english
	
		puts "Expression: " + expression
		puts "Reading: " + reading
		puts "Kanji: " + kanji
		puts "Hinshi: " + hinshi
		puts "Definition: " + definition
		puts "Sentence: " + sentence
		puts
	end

	return 
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
	puts
	puts "word: " + word
	i = i + 1
	url_front = "https://dictionary.goo.ne.jp/srch/all/".force_encoding("UTF-8") 
	url_end = "/m0u/".force_encoding("UTF-8")
	url = url_front + word + url_end
	response = openPage(URI.encode(url))

	page = Nokogiri::HTML(response)

	title = page.css('title').text


	if title.include? "で始まる言葉"
		results = selectMatchingEntries(page, word)
		if results.length == 0
			puts "No results"
			puts
			missing.push(word)
			next
		end
	end

	puts results
	results.size = results_number

	results.each do |result| 
		response = openPage(result)
		page = Nokogiri::HTML(response)

		title = page.css('title').text

		puts "Page Title: " + title

		if title.include? "英語で訳す"
			puts "english translation result"
			puts
			missing.push(word)#Search elsewhere?
			next
		end
			     
		if title.include? "404"
			puts "result is 404"
			missing.push(word)#
			next
		end

		if title.include? "goo国語辞書"
			puts "goo国語辞書 result"
			processKokugo(page, word)
		end

		if title.include? "四字熟語"
			puts "四字熟語 result"
			next
			processYoji(page)
		end
	end



		
	
#	definitions_list = page.css(".contents_area .contents .text")
#	reading = page.css(".contents-wrap-b-in .basic_title h2").text
	next
#	reading = reading.gsub("】 の解説", "")
#	reading, kanji, extra = reading.split("【")
#	kanji = ""
#	if reading_kanji.size > 1
#		kanji = reading_kanji[1]#if more than 1?
#	end
#	reading = reading_kanji[0].strip
#	puts reading
exit
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

