package SetTemplateLink::Transformer;

use strict;
use File::Spec;

sub hdlr_template_param_edit_template {
    my ( $cb, $app, $param, $tmpl ) = @_;

    my $q           = $app->param;
    my $template_id = $q->param('id');
    my $blog_id     = $q->param('blog_id');
    my $plugin  = MT->component('SetTemplateLink');
    my $config_path =
      $plugin->get_config_value( 'set_template_path', "blog:$blog_id" );

    my $template    = MT::Template->load({ id => $template_id, blog_id => $blog_id });
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
