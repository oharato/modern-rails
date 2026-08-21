module ApplicationHelper
  def category_icon(slug)
    case slug.to_s
    when "craft-art" then "🎨"
    when "woodwork" then "🪵"
    when "ceramics" then "🏺"
    when "leather" then "👜"
    when "digital" then "💻"
    else "📦"
    end
  end

  def product_image_tag(product, extra_class: "w-full h-full object-cover")
    if product.images.attached?
      # Use relative path so it works across any hostname (e.g. nuc7.local, localhost, IP address)
      blob_url = rails_storage_proxy_path(product.images.first, only_path: true)
      image_tag blob_url, class: extra_class, alt: product.name, loading: "lazy"
    else
      dummy_product_svg(product, extra_class)
    end
  rescue => e
    dummy_product_svg(product, extra_class)
  end

  def dummy_product_svg(product, extra_class = "w-full h-full object-cover")
    colors = {
      "craft-art" => ["#4f46e5", "#818cf8"],
      "woodwork"  => ["#d97706", "#f59e0b"],
      "ceramics"  => ["#059669", "#10b981"],
      "leather"   => ["#b45309", "#d97706"],
      "digital"   => ["#7c3aed", "#a78bfa"]
    }
    c1, c2 = colors[product.category&.slug] || ["#475569", "#64748b"]

    content_tag :div, class: "#{extra_class} flex flex-col items-center justify-center p-4 text-white text-center select-none shadow-inner", style: "background: linear-gradient(135deg, #{c1}, #{c2});" do
      concat content_tag(:div, category_icon(product.category&.slug), class: "text-4xl sm:text-5xl mb-2 filter drop-shadow")
      concat content_tag(:div, product.name, class: "font-bold text-xs sm:text-sm tracking-tight line-clamp-2 px-2")
      concat content_tag(:div, product.category&.name, class: "text-[10px] opacity-80 mt-1 font-medium bg-black/20 px-2 py-0.5 rounded-full")
    end
  end
end
