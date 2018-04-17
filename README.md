# Tivoli

Tivoli is a little script that allows you to programmatically create subject
access request documents (based on 'Wet bescherming persoonsgegevens') based on
a CSV file.

The letter is taken from Bits of Freedom's excellent [PIM](https://pim.bof.nl/).

## Installation

Install the required dependencies.

```bash
bundle install
```

## Usage

First, prepare a CSV file with your own address on the first row:

```
Jan Janssen,Straat 1,1234 AB,Amsterdam
TivoliVredenburg,Vlaamse Toren 7,3511 WC,Utrecht
```

```bash
# run the script with your CSV file, e.g. export.csv
bundle exec ruby tivoli.rb export.csv
```

Find the generated PDFs in the `/out` directory.
