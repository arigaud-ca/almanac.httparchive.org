#standardSQL
# percientile data from wpt_bodies per device

# returns all the data we need from _markup
CREATE TEMPORARY FUNCTION get_markup_info(markup_string STRING)
RETURNS STRUCT<
  images_img_total INT64
  # add more properties here...
> LANGUAGE js AS '''
var result = {};
try {
    //var markup = JSON.parse(markup_string); // LIVE

    // TEST
    var markup = {
      "images": {
          "img": {
              "total": Math.floor(Math.random() * 100)
          }
      }
    }; 

    if (Array.isArray(markup) || typeof markup != 'object') return result;

    if (markup.images) {
      if (markup.images.img) {
        result.images_img_total = markup.images.img.total;
      }
    }

    // add more code to set result properties here...

} catch (e) {}
return result;
''';

SELECT
  percentile,
  client,
  COUNT(DISTINCT url) AS total,

  # img per page
  APPROX_QUANTILES(markup_info.images_img_total, 1000)[OFFSET(percentile * 10)] AS img_count,

FROM (
  SELECT 
    _TABLE_SUFFIX AS client,
    percentile,
    url,
    get_markup_info('') AS markup_info # TEST
    #get_markup_info(JSON_EXTRACT_SCALAR(payload, '$._markup')) AS markup_info # LIVE
  FROM
  `httparchive.sample_data.pages_*`, # TEST
  UNNEST([10, 25, 50, 75, 90]) AS percentile
)
GROUP BY
  percentile,
  client
ORDER BY
  percentile,
  client
