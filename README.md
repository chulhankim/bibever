bibever
=======

Export a bibTeX file from your Evernote notebook.

## Requirements

### [Ruby][1]

Install [Ruby][1] on your machine. This application has been tested with v2.1.1.

### [Evernote SDK][2] for [Ruby][1]

This can be easily installed by

    $ gem update --system
    $ gem install evernote_oauth

### [Evernote][3] Developer Token

Because this application is not a web application, OAuth is not necessary. Even if OAuth is used, you need to re-authorise everytime you run this app through a browser, which is really annoying! So, I decided to use developer token. **Be careful. Anyone can access your [Evernote][3] with your developer token. DO NOT SHARE and KEEP IT SECURED.**

[This link](https://www.evernote.com/api/DeveloperToken.action) leads to the webpage that you can create your own developer token.

## How to use

### Build your bibliography database in an [Evernote][3] notebook

Make a notebook named `ref`. Add bibliography items in that note. One note for one article/paper/book. This app does not check validity of your notes (for now), so that you need to be clear when you add bibliography items. Please check [wiki](https://github.com/chulhankim/bibever/wiki/How-to-manage-your-bibliography-consistently) for the consistent management of your bibliography. Here are some rules.

- The title of the note is the title of the item.
- Each attribute needs to be written next to a bullet.
- No need to use the quotation mark `"`.
- Attributes go on top of the note. You can write your personal comments after them.
- Of course you can add PDFs and other resources in the notes!

For example, check [this note](https://sandbox.evernote.com/shard/s1/sh/470417cc-e80d-4721-b4d8-9288d9bc735d/65f3f6d35769522ab25b65fc2531a6b6). This will produce

```tex
@inproceedings{ckim10,
    author: "Kim, Chulhan and Henry, III, Robert and Smith, Dobda",
    title: "Bibever: Evernote to bibTeX",
    year: "2210",
    pages: "222--333",
    month: oct,
    booktitle: "Proceedings of the 2210 International Conference of Stupidity",
    address: "Rome, Italy",
    url: "https://www.google.com"
}
```

### Make a file of your devloper token

Make a file that includes only a single line of your developer token. Again, be careful.

### Run

    $ ruby bibever.rb

This will read `dt.txt` to get your developer token and produce `ref.bib` in the same folder. You can customise it by giving arguments as

    $ ruby bibever.rb -d "path/to/developer_token_file" -o "path/to/output_file.bib"

For example,

    $ ruby bibever.rb -d "/Users/username/desktop/token.txt" -o "output.bib"

will produce `output.bib` file in the same folder with `bibever.rb` after reading `token.txt` in `/Users/username/desktop` folder.

[1]: https://www.ruby-lang.org "Ruby"
[2]: http://dev.evernote.com/ "Evernote Developers"
[3]: http://evernote.com/ "Evernote"