#legacySQL

-- Copyright 2017 Google Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

SELECT
  n.name AS name,
  n.name_count AS name_count,
  b.rowkey AS phrase,
  b.cf1.usage_count.cell.value AS phrase_count
FROM (
  SELECT
    name AS name,
    SUM(number) AS name_count,
    CONCAT(LOWER(name), ' plays chess') AS phrase
  FROM
    [bigquery-public-data:usa_names.usa_1910_current]
  GROUP BY
    name,
    phrase ) n
JOIN
  [swast-bigtable-examples:bigtableexamples.books] b
ON
  b.rowkey = n.phrase
ORDER BY
  phrase_count DESC

