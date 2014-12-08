require "digest/md5"
require 'evernote-thrift'
require 'rexml/document'

class Bibitem
  attr_accessor :key, :type, :title, :author, :journal, :year, :volume, :number, :pages, :month,
                :publisher, :booktitle, :series, :address, :chapter, :edition, :school, :url

  def initialize(type, title)
    @type = type
    @title = title
  end

  def to_s
    puts "title: \"#{@title}\"" if @title != nil
    puts "citation key: \"#{@key}\"" if @key != nil
    puts "type: \"#{@type.to_s}\"" if @type != nil
    puts "author: \"#{@author}\"" if @author != nil
    puts "journal: \"#{@journal}\"" if @journal != nil
    puts "year: \"#{@year}\"" if @year != nil
    puts "volume: \"#{@volume}\"" if @volume != nil
    puts "number: \"#{@number}\"" if @number != nil
    puts "pages: \"#{@pages}\"" if @pages != nil
    puts "month: #{@month}" if @month != nil
    puts "publisher: \"#{@publisher}\"" if @publisher != nil
    puts "booktitle: \"#{@booktitle}\"" if @booktitle != nil
    puts "series: \"#{@series}\"" if @series != nil
    puts "address: \"#{@address}\"" if @address != nil
    puts "chapter: \"#{@chapter}\"" if @chapter != nil
    puts "edition: \"#{@edition}\"" if @edition != nil
    puts "school: \"#{@school}\"" if @school != nil
    puts "url: \"#{@url}\"" if @url != nil
  end

  def req_ok?
    case @type
    when :article
      (@author != nil) && (@journal != nil) && (@year != nil)
    when :book
      (@author != nil) && (@publisher != nil) && (@year != nil)
    when :incollection
      (@author != nil) && (@booktitle != nil) && (@year != nil)
    when :inproceedings
      (@author != nil) && (@booktitle != nil) && (@year != nil)
    when :phdthesis
      (@author != nil) && (@school != nil) && (@year != nil)
    when :mastersthesis
      (@author != nil) && (@school != nil) && (@year != nil)
    else
      true
    end
  end

  def generate_bibtex
    bib = "@#{@type}\{"
    if @key == nil
      if @year.to_s.to_i == 0
        y = "0"
      else
        y = @year.to_s[2..3]
      end
      first_author = @author.split(" and ")[0]
      first_author_split = first_author.split(", ")
      first_author_key = (toalp(first_author_split[-1][0]) +
                          toalp(first_author_split[0])).gsub(/\s/, '') + y +
      @title[0..1].gsub(/\s/, '') +
      @title[-2..-1].gsub(/\s/, '')
      bib << first_author_key.downcase + ","
    else
      bib << @key + ","
    end

    organise_author
    bib << "\n\tauthor = \"#{@author}\"," if @author != nil
    bib << "\n\ttitle = \"#{@title}\"," if @title != nil
    bib << "\n\tjournal = \"#{@journal}\"," if @journal != nil
    bib << "\n\tyear = \"#{@year}\"," if @year != nil
    bib << "\n\tvolume = \"#{@volume}\"," if @volume != nil
    bib << "\n\tnumber = \"#{@number}\"," if @number != nil
    bib << "\n\tpages = \"#{@pages}\"," if @pages != nil
    bib << "\n\tmonth = #{@month}," if @month != nil
    bib << "\n\tpublisher = \"#{@publisher}\"," if @publisher != nil
    bib << "\n\tbooktitle = \"#{@booktitle}\"," if @booktitle != nil
    bib << "\n\tseries = \"#{@series}\"," if @series != nil
    bib << "\n\taddress = \"#{@address}\"," if @address != nil
    bib << "\n\tchapter = \"#{@chapter}\"," if @chapter != nil
    bib << "\n\tedition = \"#{@edition}\"," if @edition != nil
    bib << "\n\tschool = \"#{@school}\"," if @school != nil
    bib << "\n\turl = \"#{@url}\"," if @url != nil

    bib = bib[0...-1] + "\n\}"
  end

  def toalp(aut)
    ind = /ç/ =~ aut
    if ind != nil
      aut[ind] = "c"
    end

    ind = /ü/ =~ aut
    if ind != nil
      aut[ind] = "u"
    end

    ind = /ö/ =~ aut
    if ind != nil
      aut[ind] = "o"
    end

    ind = /ó/ =~ aut
    if ind != nil
      aut[ind] = "o"
    end

    ind = /ι/ =~ aut
    if ind != nil
      aut[ind] = "i"
    end

    ind = /é/ =~ aut
    if ind != nil
      aut[ind] = "e"
    end

    return aut
  end

  def organise_author
    ind = /ç/ =~ @author
    if ind != nil
      @author[ind] = "{\\c c}"
    end

    ind = /ü/ =~ @author
    if ind != nil
      @author[ind] = "{\\\"u}"
    end

    ind = /ö/ =~ @author
    if ind != nil
      @author[ind] = "{\\\"o}"
    end

    ind = /ó/ =~ @author
    if ind != nil
      @author[ind] = "\\\'{o}"
    end

    ind = /ι/ =~ @author
    if ind != nil
      @author[ind] = "$itoa$"
    end

    ind = /é/ =~ @author
    if ind != nil
      @author[ind] = "{\\\'e}"
    end
  end
end

puts "Organising arguments..."

developer_token_path = ""
bib_out_path = ""
for i in 0..ARGV.length
  if ARGV[i] == "-d"
    developer_token_path = ARGV[i + 1]
  elsif ARGV[i] == "-o"
    bib_out_path = ARGV[i + 1]
  end
end

puts "Reading your developer token."

developer_token_path = "dt.txt" if developer_token_path == ""
begin
  file = File.new(developer_token_path, "r")
  auth_token = file.gets
  file.close
rescue => e
  puts "Error during reading your developer token file."
  exit(1)
end

start_time = Time.now

puts "Connecting..."

# UserStore (common)
# Need to be changed for production service.
evernote_host = "www.evernote.com"
user_store_url = "https://#{evernote_host}/edam/user"

user_store_transport = Thrift::HTTPClientTransport.new(user_store_url)
user_store_protocol = Thrift::BinaryProtocol.new(user_store_transport)
user_store = Evernote::EDAM::UserStore::UserStore::Client.new(user_store_protocol)

puts "Checking version..."
version_ok = user_store.checkVersion("Evernote EDAMTest (Ruby)",
             Evernote::EDAM::UserStore::EDAM_VERSION_MAJOR,
             Evernote::EDAM::UserStore::EDAM_VERSION_MINOR)
puts "OK?: #{version_ok}"
exit(1) unless version_ok

puts "Logging in..."

# Access Evernote userdata using the Developer Token.
begin
  note_store_url = user_store.getNoteStoreUrl(auth_token)
  note_store_transport = Thrift::HTTPClientTransport.new(note_store_url)
  note_store_protocol = Thrift::BinaryProtocol.new(note_store_transport)
  note_store = Evernote::EDAM::NoteStore::NoteStore::Client.new(note_store_protocol)
rescue => e
  puts "Error during logging in. Check your developer token."
end

puts "Getting notes..."

# List all of the notebooks in the user's account
notebooks = note_store.listNotebooks(auth_token)

puts "Accessing your bib database..."

def ref_guid(notebooks)
  notebooks.each do |notebook|
    return notebook.guid if notebook.name == "ref"
  end
  puts "There is no notebook named \"ref\"."
  exit(1)
end

ref_filter = Evernote::EDAM::NoteStore::NoteFilter.new
ref_filter.notebookGuid = ref_guid(notebooks)
ref_note_list_meta = note_store.findNotesMetadata(auth_token, ref_filter, 0,
                     Evernote::EDAM::Limits::EDAM_USER_NOTES_MAX,
                     Evernote::EDAM::NoteStore::NotesMetadataResultSpec.new)
ref_note_list = ref_note_list_meta.notes

puts "#{ref_note_list.length} items in your bib database."

exit(1) if ref_note_list.empty?

puts "Processing...\n"

bib_list = []
ref_note_list.each do |ref|
  note = note_store.getNote(auth_token, ref.guid, true, false, false, false)
  note_args = {}
  note_args[:title] = note.title

  # Create a hash from reading all list elements of the bibitem.
  doc = REXML::Document.new(note.content)
  REXML::XPath.each(doc, "//li") do |e|
    wip = e.text.split(":")
    next if wip.length == 1
    wip2 = wip[1..-1].inject("") {|sum, t| sum + t + ":"}
    wip2 = wip2[1...-1]
    note_args[wip[0].strip.downcase.to_sym] = wip2
  end
  note_args[:url] = REXML::XPath.first(doc, "//li/a").text if note_args[:url] == ""

  # Process the hash into a Bibitem object.
  if note_args[:type] == nil
    puts "Warning: the item \"#{note_args[:title]}\" does not specify its type. Skipped."
    next
  end
  bib = Bibitem.new(note_args[:type], note_args[:title])
  bib.author = note_args[:author] if note_args[:author] != nil
  bib.journal = note_args[:journal] if note_args[:journal] != nil
  bib.year = note_args[:year] if note_args[:year] != nil
  bib.volume = note_args[:volume] if note_args[:volume] != nil
  bib.number = note_args[:number] if note_args[:number] != nil
  bib.pages = note_args[:pages] if note_args[:pages] != nil
  bib.month = note_args[:month] if note_args[:month] != nil
  bib.publisher = note_args[:publisher] if note_args[:publisher] != nil
  bib.booktitle = note_args[:booktitle] if note_args[:booktitle] != nil
  bib.series = note_args[:series] if note_args[:series] != nil
  bib.address = note_args[:address] if note_args[:address] != nil
  bib.chapter = note_args[:chapter] if note_args[:chapter] != nil
  bib.edition = note_args[:edition] if note_args[:edition] != nil
  bib.school = note_args[:school] if note_args[:school] != nil
  bib.url = note_args[:url] if note_args[:url] != nil
  bib.key = note_args[:key] if note_args[:key] != nil

  # Add to the list
  bib_list.push(bib)
end

bib_out = bib_list.inject("") {|sum, b| sum + b.generate_bibtex + "\n"}
bib_out = bib_out.chomp

puts "Saving..."

# Save it into a bib file.
bib_out_path = File.dirname(__FILE__) + "/ref.bib" if bib_out_path == ""
begin
  file = File.new(bib_out_path, "w+")
  file.write(bib_out)
  file.close
rescue => e
  puts "Error during saving bib file."
end

puts "Done."
# puts bib_out
puts "Elapsed time: #{Time.now - start_time} sec."
