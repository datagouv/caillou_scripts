#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'csv'
require 'nokogiri'
require 'time'

# Script to extract all CERFA forms from service-public.gouv.fr
# This script will scrape all 886 forms from the website and save them to structured files.

class CerfaExtractor
  BASE_URL = 'https://www.service-public.gouv.fr'
  FORMS_URL = 'https://www.service-public.gouv.fr/particuliers/recherche?rubricFilter=serviceEnLigne&keyword=&rubricTypeFilter=formulaire'
  
  def initialize
    @forms_data = []
    @session = Net::HTTP.new(URI.parse(BASE_URL).host, 443)
    @session.use_ssl = true
    @session.read_timeout = 30
    @session.open_timeout = 30
  end

  def get_page_content(url)
    uri = URI(url)
    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    
    begin
      response = @session.request(request)
      if response.code == '200'
        Nokogiri::HTML(response.body)
      else
        puts "Error fetching #{url}: HTTP #{response.code}"
        nil
      end
    rescue => e
      puts "Error fetching #{url}: #{e.message}"
      nil
    end
  end

  def extract_forms_from_page(doc)
    forms = []
    
    # Look for form links in the page using multiple selectors
    form_selectors = [
      'a[href*="/particuliers/vosdroits/R"]',  # Service Public form links
      'a[href*="formulaire"]',                 # Links containing "formulaire"
      'a[href*="cerfa"]',                      # Links containing "cerfa"
      'a[href*="demande"]',                    # Links containing "demande"
      'a[href*="declaration"]',                # Links containing "declaration"
      'a[href*="attestation"]',                # Links containing "attestation"
      'a[href*="requete"]',                    # Links containing "requete"
      'a[href*="bulletin"]'                    # Links containing "bulletin"
    ]
    
    form_selectors.each do |selector|
      doc.css(selector).each do |link|
        href = link['href']
        text = link.text.strip
        
        next if text.empty? || href.nil?
        
        # Check if this looks like a form link
        if form_link?(href, text)
          form_data = {
            title: text,
            url: absolute_url(href),
            form_number: extract_form_number(text),
            description: extract_description(link)
          }
          
          # Avoid duplicates
          unless forms.any? { |f| f[:url] == form_data[:url] }
            forms << form_data
            puts "Found form: #{form_data[:title]}"
          end
        end
      end
    end
    
    # Also look for forms in list items or divs that might contain form information
    doc.css('li, .result-item, .form-item').each do |item|
      link = item.css('a').first
      next unless link
      
      href = link['href']
      text = link.text.strip
      
      if form_link?(href, text)
        form_data = {
          title: text,
          url: absolute_url(href),
          form_number: extract_form_number(text),
          description: extract_description(item)
        }
        
        # Avoid duplicates
        unless forms.any? { |f| f[:url] == form_data[:url] }
          forms << form_data
          puts "Found form: #{form_data[:title]}"
        end
      end
    end
    
    forms
  end

  def form_link?(href, text)
    return false if href.nil? || text.empty?
    
    # Check for common form patterns
    form_indicators = %w[
      formulaire cerfa demande declaration attestation requete bulletin
    ]
    
    # Check if URL contains form-related paths
    if href.downcase.match?(/formulaire|cerfa|demande/)
      return true
    end
    
    # Check if text contains form indicators
    if form_indicators.any? { |indicator| text.downcase.include?(indicator) }
      return true
    end
    
    false
  end

  def extract_form_number(text)
    # Look for patterns like "Formulaire 12345*01" or "CERFA 12345"
    patterns = [
      /Formulaire\s+(\d+\*\d+)/,
      /CERFA\s+(\d+)/,
      /(\d{5}\*\d{2})/,
      /Formulaire\s+(\d+)/
    ]
    
    patterns.each do |pattern|
      match = text.match(pattern)
      return match[1] if match
    end
    
    nil
  end

  def extract_description(link_element)
    # Look for description in parent elements or siblings
    parent = link_element.parent
    return '' unless parent
    
    # Get all text from parent, excluding the link text
    parent_text = parent.text.strip
    link_text = link_element.text.strip
    
    if parent_text != link_text
      parent_text.gsub(link_text, '').strip
    else
      ''
    end
  end

  def get_pagination_info(doc)
    pagination_info = {
      current_page: 1,
      total_pages: 1,
      next_url: nil
    }
    
    # Look for pagination elements
    pagination = doc.css('nav.pagination, .pagination').first
    
    if pagination
      # Find next page link
      next_link = pagination.css('a').find { |a| a.text.match?(/suivant|next|>/i) }
      if next_link && next_link['href']
        pagination_info[:next_url] = absolute_url(next_link['href'])
      end
    end
    
    # Try to find total number of results
    results_text = doc.text.match(/\d+\s+résultats?/)
    if results_text
      # Extract number from text like "886 formulaires"
      numbers = results_text[0].scan(/\d+/)
      pagination_info[:total_forms] = numbers.first.to_i if numbers.any?
    end
    
    pagination_info
  end

  def absolute_url(relative_url)
    return relative_url if relative_url.start_with?('http')
    
    if relative_url.start_with?('/')
      "#{BASE_URL}#{relative_url}"
    else
      "#{BASE_URL}/#{relative_url}"
    end
  end

  def extract_all_forms
    puts "Starting extraction of all CERFA forms..."
    
    all_forms = []
    
    # First, let's try to get all forms by using different pagination approaches
    # The website shows "886 formulaires" so we need to find the right pagination method
    
    # Method 1: Try with different page parameters
    (1..100).each do |page_num|  # Try up to 100 pages to get all forms
      puts "Processing page #{page_num}..."
      
      # Try different URL patterns for pagination
      page_urls = [
        "#{FORMS_URL}&page=#{page_num}",
        "#{FORMS_URL}&p=#{page_num}",
        "#{FORMS_URL}&offset=#{(page_num - 1) * 20}",
        "#{FORMS_URL}&start=#{(page_num - 1) * 20}"
      ]
      
      page_forms = []
      page_urls.each do |url|
        doc = get_page_content(url)
        next unless doc
        
        forms = extract_forms_from_page(doc)
        if forms.any?
          page_forms = forms
          puts "Found #{forms.length} forms on page #{page_num} using URL: #{url}"
          break
        end
      end
      
      # If no forms found on this page, we've likely reached the end
      if page_forms.empty?
        puts "No forms found on page #{page_num}, stopping pagination"
        break
      end
      
      all_forms.concat(page_forms)
      sleep(1) # Be respectful to the server
      
      # If we've found a reasonable number of forms, we might be done
      if all_forms.length >= 800
        puts "Found #{all_forms.length} forms, which seems close to the expected 886"
        break
      end
    end
    
    # Method 2: Try to get all forms in one request by increasing the page size
    puts "Trying to get all forms in one request..."
    large_page_urls = [
      "#{FORMS_URL}&limit=1000",
      "#{FORMS_URL}&size=1000",
      "#{FORMS_URL}&per_page=1000",
      "#{FORMS_URL}&count=1000"
    ]
    
    large_page_urls.each do |url|
      doc = get_page_content(url)
      next unless doc
      
      forms = extract_forms_from_page(doc)
      if forms.length > all_forms.length
        puts "Found #{forms.length} forms using large page size: #{url}"
        all_forms = forms
        break
      end
    end
    
    # Method 3: Try different search parameters to find more forms
    puts "Trying different search parameters..."
    search_variations = [
      "#{BASE_URL}/particuliers/recherche?rubricFilter=serviceEnLigne&keyword=formulaire&rubricTypeFilter=formulaire",
      "#{BASE_URL}/particuliers/recherche?rubricFilter=serviceEnLigne&keyword=cerfa&rubricTypeFilter=formulaire",
      "#{BASE_URL}/particuliers/recherche?rubricFilter=serviceEnLigne&keyword=demande&rubricTypeFilter=formulaire",
      "#{BASE_URL}/particuliers/recherche?rubricFilter=serviceEnLigne&keyword=declaration&rubricTypeFilter=formulaire",
      "#{BASE_URL}/particuliers/recherche?rubricFilter=serviceEnLigne&keyword=attestation&rubricTypeFilter=formulaire"
    ]
    
    search_variations.each do |url|
      doc = get_page_content(url)
      next unless doc
      
      forms = extract_forms_from_page(doc)
      if forms.any?
        puts "Found #{forms.length} forms using search variation: #{url}"
        # Add new forms to the collection
        forms.each do |form|
          unless all_forms.any? { |f| f[:url] == form[:url] }
            all_forms << form
            puts "Added new form: #{form[:title]}"
          end
        end
      end
    end
    
    puts "Extraction complete. Found #{all_forms.length} forms total."
    all_forms
  end

  def save_forms_to_files(forms)
    Dir.mkdir('/home/caillou/Apps/datagouv/caillou_scripts/cerfa_extract') unless Dir.exist?('/home/caillou/Apps/datagouv/caillou_scripts/cerfa_extract')
    
    # Save as JSON
    json_file = '/home/caillou/Apps/datagouv/caillou_scripts/cerfa_extract/cerfa_forms.json'
    File.write(json_file, JSON.pretty_generate(forms))
    puts "Saved #{forms.length} forms to #{json_file}"
    
    # Save as CSV
    csv_file = '/home/caillou/Apps/datagouv/caillou_scripts/cerfa_extract/cerfa_forms.csv'
    if forms.any?
      CSV.open(csv_file, 'w', encoding: 'UTF-8') do |csv|
        csv << forms.first.keys # Header
        forms.each { |form| csv << form.values }
      end
      puts "Saved #{forms.length} forms to #{csv_file}"
    end
    
    # Save as TSV
    tsv_file = '/home/caillou/Apps/datagouv/caillou_scripts/cerfa_extract/cerfa_forms.tsv'
    if forms.any?
      CSV.open(tsv_file, 'w', col_sep: "\t", encoding: 'UTF-8') do |csv|
        csv << forms.first.keys # Header
        forms.each { |form| csv << form.values }
      end
      puts "Saved #{forms.length} forms to #{tsv_file}"
    end
    
    # Save summary
    summary_file = '/home/caillou/Apps/datagouv/caillou_scripts/cerfa_extract/extraction_summary.txt'
    File.write(summary_file, generate_summary(forms))
    puts "Saved extraction summary to #{summary_file}"
  end

  def generate_summary(forms)
    form_numbers = forms.map { |form| form[:form_number] }.compact
    unique_numbers = form_numbers.uniq
    
    summary = <<~SUMMARY
      CERFA Forms Extraction Summary
      =============================

      Total forms extracted: #{forms.length}
      Extraction date: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}

      Forms with CERFA numbers: #{form_numbers.length}
      Unique form numbers: #{unique_numbers.length}

      Sample forms:
    SUMMARY
    
    forms.first(10).each_with_index do |form, index|
      summary += "#{index + 1}. #{form[:title]} (#{form[:form_number] || 'No number'})\n"
    end
    
    summary
  end

  def run
    begin
      # Extract all forms
      forms = extract_all_forms
      
      if forms.any?
        # Save to files
        save_forms_to_files(forms)
        puts "\n✅ Successfully extracted #{forms.length} CERFA forms!"
        puts "📁 Files saved in: /home/caillou/Apps/datagouv/caillou_scripts/cerfa_extract/"
      else
        puts "❌ No forms were extracted. Please check the website structure."
      end
      
    rescue => e
      puts "❌ Extraction failed: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  extractor = CerfaExtractor.new
  extractor.run
end
