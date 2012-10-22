package SetTemplateLink::Transformer;

use strict;
use File::Spec;
use Data::Dumper;

sub hdlr_template_source_edit_template {
		my ($cb, $app, $tmpl_ref) = @_;
		my $jquery_old = <<EOF; 
    jQuery('button.save, button.publish').click(function() {
        syncEditor();
        jQuery('form#template-listing-form > input[name=__mode]').val('save');
    });
EOF
		$jquery_old = quotemeta($jquery_old);
		$jquery_old =~ s!(\\ )+!\\s+!g;
		my $jquery_new = <<EOF;
    jQuery('button.save, button.publish').click(function() {
        syncEditor();
        jQuery('form#template-listing-form > input[name=__mode]').val('save');
    });
    jQuery('input#linked_file').val( jQuery('input#linked_file').val().replace(/([^\/]+?)\$/, jQuery('input#title').val()+ "\.mtml"));
		jQuery('button.save').focus();
EOF
		$$tmpl_ref =~ s!$jquery_old!$jquery_new!;
}

sub hdlr_template_param_edit_template {
    my ( $cb, $app, $param, $tmpl ) = @_;

    my $blog_id = $app->blog->id;
    my $plugin  = MT->component('SetTemplateLink');
    my $config_path =
      $plugin->get_config_value( 'set_template_path', "blog:$blog_id" );
    my $q           = $app->param;
    my $blog_id     = $q->param('blog_id');
    my $template_id = $q->param('id');
    my $template    = MT::Template->load($template_id);
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
