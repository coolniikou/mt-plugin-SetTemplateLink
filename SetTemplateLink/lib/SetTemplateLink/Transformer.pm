package SetTemplateLink::Transformer;

use strict;
use File::Spec;
use Data::Dumper;

sub hdlr_template_source_edit_template {
    my ($cb, $app, $tmpl_ref) = @_;
    my $jquery_old = <<EOF; 
    jQuery(window).bind('pre_autosave', function(){
        syncEditor();
    });
EOF
    $jquery_old = quotemeta($jquery_old);
    $jquery_old =~ s!(\\ )+!\\s+!g;
    my $jquery_new = <<EOF;
    jQuery(window).bind('pre_autosave', function(){
        syncEditor();
    });
    if(!jQuery('#title').val().match(/[^\x01-\x7E]/g)) {
        jQuery('input#linked_file').val( jQuery('input#linked_file').val().replace(/([^\/]+?)\$/, jQuery('input#title').val()+ "\.mtml"));
        jQuery('button.save').focus();
    }
    else {
        jQuery('#title')
          .on('blur, keydown, keyup', function() {
                  var input = jQuery('#title').val()
                  , change = jQuery('#linked_file').val()
                      .replace(/[^\/]+\$/, input+ "\.mtml");
           				jQuery('#linked_file').val(change);
						});
    }
EOF
    $$tmpl_ref =~ s!$jquery_old!$jquery_new!;
}

sub hdlr_template_param_edit_template {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $q           = $app->param;
    my $blog_id     = $q->param('blog_id');
    my $template_id = $q->param('id');
    my $plugin  = MT->component('SetTemplateLink');
    my $config_path =
      $plugin->get_config_value( 'set_template_path', "blog:$blog_id" );
    $app->log({  message => $config_path });
    my $template    = MT::Template->load($template_id);
    $app->log({  message => Dumper($template) });
    my $linked_file =
        $template->linked_file()
      ? $template->linked_file 
      : sub {
        my $basename = $template->identifier . '.mtml';
        return File::Spec->catfile( $config_path, $basename );
      };
    $param->{linked_file} = $linked_file if !$param->{linked_file};
}

1;
