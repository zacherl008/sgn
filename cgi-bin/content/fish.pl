use strict;
use CXGN::Page;
my $page=CXGN::Page->new('my page','marty');
$page->header("SGN FISH submission guidelines", "SGN FISH Submission Guidelines");
print qq|<div>
<p>This document describes what we at SGN are prepared to accept for FISH
experiment data. Please <a href="/contact/form">contact us</a> if you have any questions about these guidelines.</p>


<p>When submitting spreads, the preferred folder layout looks like this:</p>

<pre>&lt;chromosome arm&gt;/&lt;BACS on arm&gt;/&lt;spreads for BAC&gt;/&lt;files for spread&gt;</pre>

<p>For example, a single spread for a BAC on chromosome 11's long arm would
be:</p>

<pre>
  Tomato_11Q/
  Tomato_11Q/BAC_323E19/
  Tomato_11Q/BAC_323E19/Spread_127/
  Tomato_11Q/BAC_323E19/Spread_127/127_composite.jpg
  Tomato_11Q/BAC_323E19/Spread_127/127_phase.jpg
  Tomato_11Q/BAC_323E19/Spread_127/127_fluorescence.jpg
</pre>

<p>Other spreads for BAC 323E19 would be beside Spread_127 in the
BAC_323E19 folder, other BACs on Tomato's 11Q arm would be beside
BAC_323E19 in the Tomato_11Q folder, and BACs on other chromosome arms
would be in folders beside Tomato_11Q.</p>

<p>The "Spread" IDs above are arbitrary, but it's best if the submitter
uses different IDs for each spread, across their entire FISHing project
(we assume that the lab already uses unique identifiers for their
experiements, so we can just use those identifiers, for simplicity).</p>

<p>Each spread's folder must have at least the 3 image files.  We'll also
store any additional per-spread datafiles beside the JPGs in the
Spread_NNN folders.</p>

<p><em>Note</em> If possible, when multiple BACs occur in the same
spread, make two distinct folders with a copy of each image in each
folder (e.g., have two folders "Spread_15" and "Spread_16", rather
than putting the images in a single folder called
&quot;Spreads_15_and_16&quot; or something).</p>

<p>For each upload of several spreads, a single spreadsheet with at
least the following columns (columns of other data will be ignored):</p>

<pre>
  BAC ID      Spread   BAC % from kc
  ------      ------   -------------
  323E19       127       86.99
  323E19       128       87.73
  323E19       129       88.27
  323E19       130       90.60
  323E19       131       90.58
  323E19       132       90.01
  323E19       133       86.37
  323E19       134       84.70
</pre>

</div>|;
$page->footer();
