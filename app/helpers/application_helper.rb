module ApplicationHelper
  # Sanitizes a URL to prevent XSS attacks
  # Only allows http, https, and protocol-relative URLs
  def sanitize_url(url)
    return nil if url.blank?

    # Parse the URI
    uri = URI.parse(url)

    # Only allow http, https, or protocol-relative URLs
    if uri.scheme.nil? || %w[http https].include?(uri.scheme.downcase)
      url
    else
      nil
    end
  rescue URI::InvalidURIError
    nil
  end
end
