defmodule HerokuConnector.ConnectionView do
  use HerokuConnector.Web, :view

  def certificate_display(dnsimple_domain, dnsimple_certificate) do
    full_certificate_name(dnsimple_domain, dnsimple_certificate) <> " (Expires: #{dnsimple_certificate.expires_on})"
  end

  def full_certificate_name(dnsimple_domain, dnsimple_certificate) do
    case dnsimple_certificate.name do
      "" -> dnsimple_domain.name
      name -> "#{name}.#{dnsimple_domain.name}"
    end
  end
end
